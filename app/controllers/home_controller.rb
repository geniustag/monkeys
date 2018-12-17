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
end
