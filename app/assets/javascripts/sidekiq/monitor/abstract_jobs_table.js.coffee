class SidekiqMonitor.AbstractJobsTable

  constructor: ->
    @api_params = {}
    @initialize()

  initialize_with_options: (options) =>
    @options = options
    @table = $(@options.table_selector)

    @columns = @options.columns
    @status_filter = null

    $.getJSON SidekiqMonitor.settings.api_url('jobs/clean')

    @table.dataTable
      bProcessing: true
      bServerSide: true
      sAjaxSource: @table.data('source')
      iDisplayLength: 10
      aaSorting: [[@columns.enqueued_at, 'desc']]
      sPaginationType: 'bootstrap'
      aoColumns: @options.column_options
      oLanguage:
        sInfo: '_TOTAL_ jobs'
        sInfoFiltered: ' (filtered from _MAX_)'
        sLengthMenu: 'Per page: _MENU_'
        sSearch: ''
      fnRowCallback: (nRow, aData, iDisplayIndex) =>
        $('.timeago', nRow).timeago()
      fnInitComplete: () =>
        filter_container = @table.siblings('.dataTables_filter')
        filter_container.find('input').attr('placeholder', 'Search...')
        filter_container.prepend '
          <div class="btn-group status-filter" data-toggle="buttons-radio">
            <button type="button" class="btn btn-small" data-value="queued">Queued</button>
            <button type="button" class="btn btn-small" data-value="running">Running</button>
            <button type="button" class="btn btn-small" data-value="complete">Complete</button>
            <button type="button" class="btn btn-small" data-value="failed">Failed</button>
          </div>'
        @status_filter = filter_container.find('.status-filter')
      fnServerData: (sSource, aoData, fnCallback) =>
        $.each @api_params, (key, value) =>
          aoData.push
            name: key
            value: @api_params[key]
        $.getJSON sSource, aoData, (json) -> fnCallback(json)

    @table.parents('.dataTables_wrapper').addClass('jobs-table-wrapper')

    @initialize_ui()

  initialize_ui: =>
    
    @table.on 'click', '.status-value', (e) =>
      tr = $(e.target).parents('tr:first')[0]
      job = @table.fnGetData(tr)
      @show_job(job)
      false
    @table.on 'click', '.retry-job', (e) =>
      id = $(e.target).attr('data-job-id')
      $.getJSON SidekiqMonitor.settings.api_url('jobs/retry/'+id), =>
        @reload_table()
      false

    $('body').on 'click', '.status-filter .btn', (e) =>
      e.stopPropagation()
      btn = $(e.target)
      btn.siblings('.btn').removeClass('active')
      btn.toggleClass('active')
      value = @status_filter.find('.active:first').attr('data-value')
      value = '' if !value?
      @table.fnFilter(value, @columns.status - 1)

    @start_polling()

  show_job: (job) =>
    return false if !job?
    
    id = job[@columns.id]
    jid = job[@columns.jid]
    class_name = job[@columns.class_name]
    name = job[@columns.name]
    started_at = job[@columns.started_at]
    duration = job[@columns.duration]
    status = job[@columns.status]
    result = job[@columns.result]
    args = job[@columns.args]

    # TODO: Make this cleaner; is there a way to grab the original value returned by the server?
    status = $("<div>#{status}</div>").find('.status-value').text()

    result_html = ''
    if status == 'failed'
      result_html = """
        <h4>Error</h4>
        #{result.message}
        <h5>Backtrace</h5>
        <pre>
        #{result.backtrace.join("\n")}
        </pre>
      """
    else if result?
      rows_html = ''
      for key, value of result
        rows_html += "<tr><td>#{key}</td><td>#{JSON.stringify(value, null, 2)}</td></tr>"
      result_html = """
        <h4>Result</h4>
        <table class="table table-striped">
          #{rows_html}
        </table>
      """

    modal_html = """
      <div class="modal hide fade job-modal" role="dialog">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">×</button>
          <h3>Job</h3>
        </div>
        <div class="modal-body">
          <table class="table table-striped">
            <tr>
              <th>ID</th>
              <td>#{id}</td>
            </tr>
            <tr>
              <th>JID</th>
              <td>#{jid}</td>
            </tr>
            <tr>
              <th>Class</th>
              <td>#{class_name}</td>
            </tr>
            <tr>
              <th>Name</th>
              <td>#{name}</td>
            </tr>
            <tr>
              <th>Args</th>
              <td>#{JSON.stringify(args, null, 2)}</td>
            </tr>
            <tr>
              <th>Started</th>
              <td>#{started_at}</td>
            </tr>
            <tr>
              <th>Duration</th>
              <td>#{duration}</td>
            </tr>
            <tr>
              <th>Status</th>
              <td>#{status}</td>
            </tr>
          </table>
          #{result_html}
          <div class="job-custom-views"></div>
        </div>
      </div>
    """
    $('.job-modal').modal('hide')
    $('body').append(modal_html)
    modal = $('.job-modal:last')
    modal.modal
      width: 480
    $.getJSON SidekiqMonitor.settings.api_url("jobs/custom_views/#{id}"), (views) ->
      html = ''
      for view in views
        html += """
          <h4>#{view['name']}</h4>
          #{view['html']}
        """
      $('.job-custom-views', modal).html(html)

  on_poll: =>
    @reload_table()

  reload_table: =>
    @table.dataTable().fnStandingRedraw()

  start_polling: =>
    setInterval =>
      @on_poll()
    , 3000

  format_time_ago: (time) =>
    if time?
      """<span class="timeago" title="#{time}">#{time}</span>"""
    else
      ""
