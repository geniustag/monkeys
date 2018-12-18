class HomeController < ApplicationController
  layout :false

  skip_before_action :require_login_or_permission

  def index
    aff_id = request.url.split("code=").last.to_i.to_s(16)
    @aff_data = "#{"0" * (64 - aff_id.size)}#{aff_id}"
  end

  def buy
    params.delete(:authenticity_token)
    txid = params.delete(:tx_hash)
    ps = params.select{|k,v| %i(player_id tran_type key_price).include?(k.to_sym) }
    e = Etransaction.create_with_txid(txid, ps)
    render json: e.try(:id) ? "OK" : e
  end

  def grab_key
    key_bought? and return render_json(false, "该KEY已被抢购")
    Etransaction.last.created_at.to_i + 5 > Time.now.to_i and return render_json(false, "请等待下一个Key的生成")
    RedisHelper.cache!("grab_key_#{params[:key_price]}", params[:address])
    render_json
  end

  def check_key
    !key_bought? ? render_json : render_json(false, "该KEY已被抢购")
  end

  private
  def render_json(res = true, data = {})
    render json: {success: res, data: data}
  end

  def key_bought?
    RedisHelper.get("grab_key_#{params[:key_price]}").presence || Etransaction.last.try(:key_price).to_i >= params[:key_price].to_i
  end
end
