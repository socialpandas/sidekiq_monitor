class SidekiqMonitor.JobsTable extends SidekiqMonitor.AbstractJobsTable

  initialize: =>
    options =
      table_selector: 'table.jobs'
      columns:
        jid: 0
        queue: 1
        class_name: 2
        name: 3
        enqueued_at: 4
        started_at: 5
        duration: 6
        message: 7
        status: 8
        result: 9
        args: 10
      column_options: [
        { bVisible: false }
        null
        null
        { bSortable: false }
        {
          fnRender: (oObj) =>
            @format_time_ago(oObj.aData[@columns.enqueued_at])
        }
        {
          fnRender: (oObj) =>
            @format_time_ago(oObj.aData[@columns.started_at])
        }
        null
        { bSortable: false }
        {
          fnRender: (oObj) =>
            status = oObj.aData[@columns.status]
            class_name = switch status
              when 'failed'
                'danger'
              when 'complete'
                'success'
              when 'running'
                'primary'
              else
                'info'
            html = """<a href="#" class="btn btn-#{class_name} btn-mini status-value">#{oObj.aData[@columns.status]}</a>"""
            if status == 'failed'
              html += """<a href="#" class="btn btn-mini btn-primary pull-right retry-job" data-job-jid="#{oObj.aData[0]}">Retry<a>"""
            html
        }
        { bVisible: false }
        { bVisible: false }
      ]
    
    return null unless $(options.table_selector).length

    @initialize_with_options(options)

$ ->
  new SidekiqMonitor.JobsTable
