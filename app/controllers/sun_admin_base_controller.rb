class SunAdminBaseController < ApplicationController
  before_filter :get_base_obj, only: [:edit, :update, :destroy, :show]
  before_filter :auth_admin, except: :show

  def index
    if ps = params.select{|a,v| klass.column_names.include?(a)}
      self.collections = paginate_objs klass.where(ps)
    else
      self.collections = paginate_objs(klass)
    end
  end

  def new
    self.single_obj = klass.new
  end

  def edit; end
  def show; end

  def create
    self.single_obj = klass.new(params[obj_str])
    to_or_not_to?(single_obj)
  end

  def update
    back_to_list single_obj.update_attributes(params[obj_str])
  end
 
  def destroy
    back_to_list(single_obj.destroy)
  end

  private

    def get_base_obj
      self.single_obj = klass.find(params[:id])
    end

    def paginate_objs(objs, paginate = true)
      base_objs = params[:sdate] ? -> { objs.order("created_at DESC").where(created_at: params[:sdate].to_datetime..(params[:edate].presence || Date.today.to_s).to_datetime)} :
        -> {objs.order("created_at DESC")}
      table_based_arr = controller_name == "members" ?  -> {base_objs.call.where("phone_number like '#{params[:user_name]}%'")} :
             -> { base_objs.call.where(member_id: Member.where("phone_number like '#{params[:user_name]}%'")) }
      cs =  params[:user_name] ? table_based_arr : base_objs
      # 数组对象不进行搜索筛选
      cs = -> { Kaminari.paginate_array(objs.sort_by(&:created_at).reverse)} if objs.is_a?(Array)
      !paginate and return cs
      cs.call.page(params[:page]).per(20)
    end
end
