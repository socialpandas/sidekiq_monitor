$.fn.dataTableExt.oApi.fnStandingRedraw = (oSettings) ->
  before = oSettings._iDisplayStart
  oSettings._iDisplayStart = before
  oSettings.oApi._fnCalculateEnd oSettings
  oSettings.oApi._fnDraw oSettings
