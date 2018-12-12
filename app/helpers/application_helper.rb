module ApplicationHelper
  include SharedHelper if defined?(SharedHelper)
  def table_class
    'table table-striped table-bordered table-hover'
  end

  def table_form_class
    'table table-form'
  end

  def link_btn(opts = {})
    primary_btn(opts)
  end

  def primary_btn(opts = {})
    style, size = [opts[:style] || 'primary', opts[:size] || 'big']
    'btn btn-' + style + ' btn-' + size
  end

  def submit_btn(title = t(:save), opts = {})
    submit_tag title, class: link_btn(style: opts[:style] || 'success mr10'), data: {disable_with: "#{opts[:disable_with] || title}中..."}
  end

  def save_and_return(f) 
    sub_btn = submit_btn 
    td = content_tag(:td, sub_btn + link_to_back(url: "/admin/#{controller_name}"), colspan: "10", align: "center")
    content_tag(:tr, td, style: 'text-align: center')
  end

  def info_link(obj, opts = {})
    edit_btn = link_to('', "/admin/" + controller_name + "/#{obj.id}", class: 'glyphicon glyphicon-info-sign mr10')
  end

  def edit_with_delete(obj, opts = {})
    edit_btn = link_to('', "/admin/" + controller_name + "/#{obj.id}/edit", class: 'glyphicon glyphicon-edit mr10')
    destroy_btn = link_to('', [:admin, obj], data: {confirm: "确定删除么?"}, method: :delete, class: 'glyphicon glyphicon-trash')
    return edit_btn if opts[:hide_destory]
    edit_btn + destroy_btn
  end

  def link_to_back(opts = {}, html_opts = {})
    link_to_btn title: t(:back), btn_style: 'primary', url: opts[:url]
  end

  def link_to_btn(opts = {}, html_opts = {})
    title = opts[:title] || 'title'
    size = opts[:size] || 'btn-big'
    btn_style = opts[:btn_style] || 'primary'
    style = {class: "btn btn-#{btn_style} ml10 " + size}.merge(html_opts)
    return link_to title, opts[:url], style if opts[:url]
    link_to(title, '#', style.merge(onclick: "history.go(-1); return false;"))
  end

  def link_to_txid(txid)
    !txid.presence and return ""
    link_to txid[0,20]+"...", txid.size == 66 ? "https://etherscan.io/tx/#{txid}" : "https://btc.com/#{txid}"
  end

  def permission_collections(model_name, name, collection)
    collection_check_boxes model_name, name, collection, :id, :name do |b|
      b.label(class: "am-checkbox am-success") do
        b.check_box("data-am-ucheck" => "") + b.object.name
      end
    end
  end

  def back_button
    link_to_back
  end
   
  def page_header(title, opts = {})
    htitle = content_tag(opts[:h] || :h3, title)
    content_tag(:div, htitle, class: "page-header")
  end

  def create_page?
    %w(new create).include?(action_name)
  end 

  def update_page?
    %w(edit update).include?(action_name)
  end 

  def top_menus
    menu = []
    login_menu = [{"login" => ""}]
    menus = [
      # {'admin' => %w(users roles resources)}
      {'admin' => %w(members)},
      {'accounts' => %w(withdraws deposits)},
      {'coinmarket' => %w(currencies markets orders)},
      {'settings' => %w(settings app_versions)},
      {'logs' => %w(feedbacks user_logs)},
      {'servers' => %w(servers services)},
      {'statistics' => %w(statistics)}
    ]
    return login_menu unless current_user
    return menus if current_user.is_admin?
    menu
  end

  def orders_summery(orders)
    buys = orders.select{|a| a.side == "buy"}
    sells = orders.select{|a| a.side == "sell"}
    {
      buy: {
        wait: buys.map(&:volume).sum,
        done: buys.map(&:finish_volume).sum
      },
      sell: {
        wait: sells.map(&:volume).sum,
        done: sells.map(&:finish_volume).sum
      }
    }
  end
end
