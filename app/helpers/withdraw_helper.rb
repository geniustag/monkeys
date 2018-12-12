module WithdrawHelper

  def operate_btn(withdraw)
    #return if withdraw.auto_withdraw_coin? && !withdraw.submitting? && !withdraw.accepted?
    case withdraw.aasm_state.try(:to_sym)
    when :submitting
      operate_link('确认', 'btn btn-primary withdraw-operate', withdraw.id, 'submit!')
    when :submitted
      operate_link('审计', 'btn btn-warning withdraw-operate mlr10', withdraw.id, 'audit!') +
      operate_link('拒绝', 'btn btn-danger withdraw-operate mlr10', withdraw.id, 'reject!')
    when :accepted
      operate_link('同意', 'btn btn-success withdraw-operate mlr10', withdraw.id, 'process!') +
      operate_link('拒绝', 'btn btn-danger withdraw-operate mlr10', withdraw.id, 'reject!')
    when :processing
      operate_link('转账', 'btn btn-success withdraw-operate mlr10', withdraw.id, 'send_coins!') +
      operate_link('拒绝', 'btn btn-danger withdraw-operate mlr10', withdraw.id, 'reject!')
    when :done
      operate_link('查看详情', 'btn btn-info withdraw-operate', withdraw.id, 'search', '#modal')
    when :suspect
      operate_link('对账', 'btn btn-default withdraw-operate mlr10', withdraw.id, 'check', '#modal') +
      operate_link('重审', 'btn btn-warning withdraw-operate mlr10', withdraw.id, 'audit!')
    else
      I18n.t("withdraw_states.aasm_state.#{withdraw.aasm_state}")
    end
  end

  # args: name, class, id, operate, is_modal
  def operate_link(*args)
      link_to(
        args[0],
        'javascript:void(0)',
        class: args[1],
        'data-id' => args[2],
        'data-operate' => args[3],
        'data-toggle' => "modal",
        'data-target' => args[4] || "#globalModa",
      )
  end

end
