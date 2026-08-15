(function (window, $) {
  'use strict';

  var SK = window.StreetKings;

  window.SKPhone.registerApp('Impound', function () {
    refreshImpoundList();
  });

  function refreshImpoundList() {
    var $list = $('#scImpoundedList');
    if (!$list.length) return;

    $list.html('<div style="color:rgba(255,255,255,0.4);text-align:center;font-size:11px;padding:10px;">Loading...</div>');

    SK.nui.post('phone:impound:getState').done(function (res) {
      if (!res || !res.ok) {
        $list.html('<div style="color:rgba(255,255,255,0.4);text-align:center;font-size:11px;padding:10px;">Failed to load impound data</div>');
        return;
      }

      var vehicles = res.vehicles || [];
      if (vehicles.length === 0) {
        $list.html('<div style="color:rgba(255,255,255,0.4);text-align:center;font-size:11px;padding:10px;">No vehicles are currently impounded!</div>');
        return;
      }

      var html = vehicles.map(function (v) {
        var releaseBtn = '';
        var remainingMins = Math.ceil(v.remainingSeconds / 60);
        var remainingText = remainingMins > 0 ? remainingMins + 'm remaining' : 'Ready for release';
        var fee = v.fee || 1000;

        if (v.remainingSeconds > 0) {
          releaseBtn = '<button class="phone-event-action pay-impound-release" data-id="' + v.id + '" style="font-size:10px;padding:4px 8px;background:#ff3b30;border:none;border-radius:3px;color:white;cursor:pointer;">Pay Release Fee (' + formatMoney(fee) + ')</button>';
        } else {
          releaseBtn = '<button class="phone-event-action free-impound-release" data-id="' + v.id + '" style="font-size:10px;padding:4px 8px;background:#34c759;border:none;border-radius:3px;color:white;cursor:pointer;">Free Release</button>';
        }

        return [
          '<div style="background:rgba(255,255,255,0.02);border:1px solid rgba(255,255,255,0.06);border-radius:4px;padding:8px;display:flex;justify-content:space-between;align-items:center;font-size:11px;margin-bottom:6px;">',
          '  <div style="display:flex;flex-direction:column;gap:2px;">',
          '    <span style="font-weight:bold;color:#ffd200;">' + v.displayName + '</span>',
          '    <span style="color:rgba(255,255,255,0.5);font-size:10px;">' + remainingText + '</span>',
          '  </div>',
          '  <div>' + releaseBtn + '</div>',
          '</div>'
        ].join('\n');
      }).join('\n');

      $list.html(html);

      $list.find('.pay-impound-release').click(function () {
        var id = $(this).attr('data-id');
        SK.nui.post('phone:impound:release', { vehicleId: id, pay: true }).done(function (result) {
          if (result && result.ok) {
            refreshImpoundList();
          } else {
            alert(result.reason || 'Insufficient funds to pay release fee!');
          }
        });
      });

      $list.find('.free-impound-release').click(function () {
        var id = $(this).attr('data-id');
        SK.nui.post('phone:impound:release', { vehicleId: id, pay: false }).done(function (result) {
          if (result && result.ok) {
            refreshImpoundList();
          }
        });
      });
    });
  }

  function formatMoney(value) {
    return '$' + Math.floor(Number(value || 0)).toLocaleString('en-US');
  }

})(window, window.jQuery);
