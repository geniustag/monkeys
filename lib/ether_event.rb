module EtherEvent
  extend self

  ADDS = CONTRACT_ADDRESSES.invert
  def parse_event(event)
    event = JSON.parse(event)
    contract_address = event["address"]
    token = ADDS[contract_address.downcase].try(:upcase)
    token.nil? and return
    tx_hash = event["transactionHash"]
    if (w = Etransaction.find_by(tx_hash: tx_hash).presence)
      Etransaction.transaction do
        w.update_attributes(event_data: event.to_json)
        w.success! if !w.success?
      end
    else
      if event["event"] == "Transfer"
        e = Etransaction.create(tx_hash: tx_hash, efrom: event["returnValues"]["from"].downcase, eto: event["returnValues"]["to"].downcase,
                         amount: event["returnValues"]["value"].to_i.to_s(16), meth: "transfer", token: token.downcase, 
                         tran_type: "transfer_event", event_data: event.to_json)
        e.success!
      end
    end
  end

  # def push_transfer(user, token, amount)
  #   !user.presence and return
  #   AppPusher.push_to_user(user, title: "您收到一笔#{token}转账", text: "您收到一笔转账，金额是#{amount}")
  # end
end
