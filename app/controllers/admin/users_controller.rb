class Admin::UsersController < SunAdminBaseController
  def index
    params[:user] = current_user
    @users = paginate_objs User # solr_search(params)
  end

  def destroy
    return back_to_list(true, "不能删除自己！") if current_user.id == @user.id
    back_to_list(@user.destroy)
  end

  def reject
    get_base_obj.rejected!
    back_to_list
  end

  def wallets
    @user = User.find(params[:id])
    @wallets = @user.wallets.page(params[:page]).per(30)
  end
end
