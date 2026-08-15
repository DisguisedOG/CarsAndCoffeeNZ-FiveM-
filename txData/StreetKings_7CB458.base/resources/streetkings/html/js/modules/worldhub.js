(function (window) {
  'use strict';

  var SK = window.StreetKings;

  function money(value) {
    return '$' + (Number(value || 0) || 0).toLocaleString('en-US');
  }

  // Active tab state
  var activeTab = 'world';
  // Selected player ID in Player Management tab
  var selectedPlayerId = null;
  // Search and filter states
  var playerSearchText = '';
  var playerFilterMode = 'all'; // 'all', 'online', 'level_desc', 'level_asc', 'wealth_desc', 'wealth_asc'

  // Confirm states for ban
  var banConfirmStep = 0; // 0 = none, 1 = first check, 2 = second check

  function renderMechanic(data) {
    var content = document.getElementById('phoneMechanicContent');
    if (!content) return;

    if (!data || !data.ok) {
      content.innerHTML = '<div class="phone-event-card"><div class="phone-event-label">Mechanic</div><div class="phone-event-name">House required</div><div class="phone-event-copy">You need to own a property before workshop access is available.</div></div>';
      return;
    }

    var html = [
      '<div class="phone-event-card">',
      '  <div class="phone-event-label">Home Workshop</div>',
      '  <div class="phone-event-name">Level ' + (data.level || 1) + ' Mechanic</div>',
      '  <div class="phone-event-copy">XP: ' + (data.xp || 0) + ' • Perk points: ' + (data.perkPoints || 0) + '</div>',
      '  <div class="phone-event-copy">Fuel: ' + (data.fuelCurrent || 0) + '/' + (data.fuelMax || 100) + ' ' + (data.fuelType || 'regular') + '</div>',
      '</div>',
      '<div class="phone-event-actions">',
      '  <button type="button" class="phone-event-action" id="phoneMechanicToggle">' + (data.unlocked ? 'Disable Workshop' : 'Enable Workshop') + '</button>',
      '</div>'
    ].join('');

    content.innerHTML = html;
    var btn = document.getElementById('phoneMechanicToggle');
    if (btn) {
      btn.addEventListener('click', function () {
        SK.nui.post('phone:mechanic:toggleWorkshop').done(function (result) {
          if (result && result.ok) {
            renderMechanic({ ok: true, level: data.level || 1, xp: data.xp || 0, perkPoints: data.perkPoints || 0, fuelCurrent: data.fuelCurrent || 0, fuelMax: data.fuelMax || 100, fuelType: data.fuelType || 'regular', unlocked: !!result.unlocked });
            return;
          }
          if (result && result.reason === 'house_required') {
            renderMechanic({ ok: false, reason: 'house_required' });
          }
        });
      });
    }
  }

  function renderWorldHub(data) {
    var content = document.getElementById('phoneWorldHubContent');
    if (!content) return;

    if (!data || !data.ok) {
      content.innerHTML = '<div class="phone-event-card"><div class="phone-event-label">ControlWorld</div><div class="phone-event-name">Not allowed</div><div class="phone-event-copy">This tablet feature is restricted to admin users only.</div></div>';
      return;
    }

    var top = data.top || {};
    var players = data.players || [];

    // Core inline styles to overlay tablet styles
    var css = [
      '<style>',
      '  .wh-container { display: flex; flex-direction: column; gap: 10px; font-family: "Inter", sans-serif; height: 100%; color: #fff; box-sizing: border-box; }',
      '  .wh-tabs { display: flex; border-bottom: 1px solid rgba(255,255,255,0.1); padding-bottom: 6px; gap: 10px; }',
      '  .wh-tab { flex: 1; cursor: pointer; padding: 6px; border-radius: 4px; font-size: 13px; font-weight: 600; text-align: center; color: rgba(255,255,255,0.6); background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.05); transition: all 0.2s; }',
      '  .wh-tab:hover { background: rgba(255,255,255,0.08); color: #fff; }',
      '  .wh-tab.active { background: #ffd200; color: #000; border: 1px solid #ffd200; }',
      '  .wh-content { flex: 1; display: flex; flex-direction: column; overflow-y: auto; max-height: calc(100vh - 180px); padding-bottom: 15px; }',
      '  .wh-card { background: rgba(255,255,255,0.02); border: 1px solid rgba(255,255,255,0.06); border-radius: 6px; padding: 10px; margin-bottom: 10px; }',
      '  .wh-title { font-size: 14px; font-weight: 700; margin-bottom: 8px; color: #ffd200; border-bottom: 1px solid rgba(255,255,255,0.05); padding-bottom: 4px; text-transform: uppercase; }',
      '  .wh-row { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 6px; }',
      '  .wh-col { display: flex; flex-direction: column; gap: 4px; width: 100%; }',
      '  .wh-label { font-size: 11px; color: rgba(255,255,255,0.5); text-transform: uppercase; }',
      '  .wh-input { width: 100%; padding: 6px; border: 1px solid rgba(255,255,255,0.12); background: rgba(0,0,0,0.4); color: #fff; border-radius: 4px; font-size: 12px; box-sizing: border-box; }',
      '  .wh-input:disabled { opacity: 0.35; cursor: not-allowed; }',
      '  .wh-btn { display: inline-block; cursor: pointer; text-align: center; border: none; padding: 6px 12px; border-radius: 4px; font-size: 12px; font-weight: 700; background: #ffd200; color: #000; transition: filter 0.2s; }',
      '  .wh-btn:hover { filter: brightness(1.1); }',
      '  .wh-btn-danger { background: #ff3b30; color: #fff; }',
      '  .wh-btn-sec { background: rgba(255,255,255,0.1); color: #fff; }',
      '  .wh-checkbox-container { display: flex; align-items: center; gap: 6px; cursor: pointer; font-size: 12px; }',
      '  .wh-player-list-scroll { max-height: 140px; overflow-y: auto; border: 1px solid rgba(255,255,255,0.08); border-radius: 4px; background: rgba(0,0,0,0.2); }',
      '  .wh-player-row { display: flex; justify-content: space-between; align-items: center; padding: 6px 8px; border-bottom: 1px solid rgba(255,255,255,0.04); cursor: pointer; font-size: 12px; }',
      '  .wh-player-row:hover { background: rgba(255,255,255,0.05); }',
      '  .wh-player-row.selected { background: rgba(255,210,0,0.12); border-left: 2px solid #ffd200; }',
      '  .wh-badge { padding: 2px 4px; border-radius: 3px; font-size: 9px; font-weight: bold; text-transform: uppercase; background: rgba(255,255,255,0.1); }',
      '  .wh-badge-online { background: rgba(52,199,89,0.2); color: #34c759; }',
      '  .wh-tag-list { display: flex; gap: 4px; }',
      '</style>'
    ].join('\n');

    // Filter players list
    var filteredPlayers = players.filter(function (player) {
      if (!playerSearchText) return true;
      var query = playerSearchText.toLowerCase();
      var idMatch = String(player.id) === query;
      var nameMatch = (player.name || '').toLowerCase().indexOf(query) !== -1;
      return idMatch || nameMatch;
    });

    // Sort players list
    if (playerFilterMode === 'level_desc') {
      filteredPlayers.sort(function (a, b) { return b.level - a.level; });
    } else if (playerFilterMode === 'level_asc') {
      filteredPlayers.sort(function (a, b) { return a.level - b.level; });
    } else if (playerFilterMode === 'wealth_desc') {
      filteredPlayers.sort(function (a, b) { return b.cash - a.cash; });
    } else if (playerFilterMode === 'wealth_asc') {
      filteredPlayers.sort(function (a, b) { return a.cash - b.cash; });
    }

    var tabWorldClass = activeTab === 'world' ? 'active' : '';
    var tabPlayersClass = activeTab === 'players' ? 'active' : '';

    var whHtml = [
      '<div class="wh-container">',
      '  <div class="wh-tabs">',
      '    <div class="wh-tab ' + tabWorldClass + '" id="whTabWorld">World Control</div>',
      '    <div class="wh-tab ' + tabPlayersClass + '" id="whTabPlayers">Players (' + players.length + ')</div>',
      '  </div>',
      '  <div class="wh-content">'
    ];

    if (activeTab === 'world') {
      // WORLD CONTROL TAB CONTENT
      var tunesOptions = (top.tunes || []).map(function (tune) {
        var selected = tune === top.activeTune ? 'selected' : '';
        return '<option value="' + tune + '" ' + selected + '>' + tune + '</option>';
      }).join('');

      whHtml.push(
        '    <div class="wh-card">',
        '      <div class="wh-title">Fuel Price Settings</div>',
        '      <div class="wh-col" style="margin-bottom: 10px;">',
        '        <span class="wh-label">Global Fuel Price ($)</span>',
        '        <input type="number" step="0.01" class="wh-input" id="whGlobalFuelPrice" value="' + (top.globalPrice || 2.40) + '" />',
        '      </div>',
        '      <div class="wh-row" style="margin-bottom: 10px;">',
        '        <label class="wh-checkbox-container">',
        '          <input type="checkbox" id="whOverrideEnabled" ' + (top.nearestStationOverrideEnabled ? 'checked' : '') + ' />',
        '          <span>Enable Station Override</span>',
        '        </label>',
        '      </div>',
        '      <div class="wh-col" style="margin-bottom: 10px;">',
        '        <span class="wh-label">Override Price ($)</span>',
        '        <input type="number" step="0.01" class="wh-input" id="whOverrideFuelPrice" value="' + (top.nearestStationOverridePrice || 2.40) + '" ' + (top.nearestStationOverrideEnabled ? '' : 'disabled') + ' />',
        '      </div>',
        '      <button class="wh-btn" id="whSaveFuel" style="width: 100%;">Save Fuel Settings</button>',
        '    </div>',
        '    <div class="wh-card">',
        '      <div class="wh-title">Loadscreen Soundtrack</div>',
        '      <div class="wh-col" style="margin-bottom: 10px;">',
        '        <span class="wh-label">Select Audio Track (MP3 only)</span>',
        '        <select class="wh-input" id="whSelectTune" style="cursor: pointer;">' + tunesOptions + '</select>',
        '      </div>',
        '      <button class="wh-btn" id="whApplyTune" style="width: 100%;">Apply Loading Music</button>',
        '    </div>'
      );
    } else {
      // PLAYERS TAB CONTENT
      var playerRows = filteredPlayers.map(function (p) {
        var isSel = selectedPlayerId === p.id ? 'selected' : '';
        return [
          '<div class="wh-player-row ' + isSel + '" data-id="' + p.id + '">',
          '  <span>[' + p.id + '] ' + (p.name || 'Player') + '</span>',
          '  <div class="wh-tag-list">',
          '    <span class="wh-badge">Lvl ' + p.level + '</span>',
          '    <span class="wh-badge wh-badge-online">Online</span>',
          '  </div>',
          '</div>'
        ].join('');
      }).join('');

      whHtml.push(
        '    <div class="wh-card">',
        '      <div class="wh-title">Player Directory</div>',
        '      <input type="text" class="wh-input" id="whPlayerSearch" placeholder="Search by name or server ID..." value="' + playerSearchText + '" style="margin-bottom: 8px;" />',
        '      <div class="wh-row" style="margin-bottom: 8px; gap: 4px;">',
        '        <select class="wh-input" id="whPlayerSort" style="flex: 1; padding: 4px;">',
        '          <option value="all" ' + (playerFilterMode === 'all' ? 'selected' : '') + '>Standard Order</option>',
        '          <option value="level_desc" ' + (playerFilterMode === 'level_desc' ? 'selected' : '') + '>Level (High-Low)</option>',
        '          <option value="level_asc" ' + (playerFilterMode === 'level_asc' ? 'selected' : '') + '>Level (Low-High)</option>',
        '          <option value="wealth_desc" ' + (playerFilterMode === 'wealth_desc' ? 'selected' : '') + '>Wealth (High-Low)</option>',
        '          <option value="wealth_asc" ' + (playerFilterMode === 'wealth_asc' ? 'selected' : '') + '>Wealth (Low-High)</option>',
        '        </select>',
        '      </div>',
        '      <div class="wh-player-list-scroll">' + (playerRows || '<div style="padding: 10px; font-size:12px; color:rgba(255,255,255,0.4);">No players matched search</div>') + '</div>',
        '    </div>'
      );

      // Player Inspection Card (if selected)
      var target = players.find(function (p) { return p.id === selectedPlayerId; });
      if (target) {
        // Render inspection stats
        var favCarsText = (target.favoriteCars || []).map(function (c, idx) {
          var minutes = Math.floor((c.seconds || 0) / 60);
          return '<div>' + (idx + 1) + '. ' + (c.displayName || c.modelName) + ' (' + c.plate + '): ' + minutes + ' min</div>';
        }).join('') || '<span style="color:rgba(255,255,255,0.3);">No driving stats recorded</span>';

        // Ban button text depending on confirmation level
        var banBtnText = 'Ban Player';
        var banBtnClass = 'wh-btn wh-btn-danger';
        if (banConfirmStep === 1) {
          banBtnText = 'Confirm: Are you sure?';
        } else if (banConfirmStep === 2) {
          banBtnText = 'Final check: are you sure your algoodz?';
          banBtnClass = 'wh-btn wh-btn-danger' + ' blink-anim';
        }

        whHtml.push(
          '    <div class="wh-card">',
          '      <div class="wh-title">Player Inspection: ' + (target.name || 'Player') + ' [' + target.id + ']</div>',
          '      <div style="font-size: 12px; display: grid; grid-template-columns: 1fr 1fr; gap: 6px; margin-bottom: 10px;">',
          '        <div>Cash: <span style="font-weight:bold;color:#ffd200;">' + money(target.cash) + '</span></div>',
          '        <div>Level: <span style="font-weight:bold;">' + target.level + '</span> (XP: ' + target.xp + ')</div>',
          '        <div>Mechanic Lvl: <span style="font-weight:bold;">' + target.mechanicLevel + '</span></div>',
          '        <div>Workshop: <span style="font-weight:bold;color:' + (target.workshopUnlocked ? '#34c759' : '#ff3b30') + '">' + (target.workshopUnlocked ? 'ENABLED' : 'DISABLED') + '</span></div>',
          '        <div>House Owner: <span style="font-weight:bold;">' + (target.hasHouse ? 'YES' : 'NO') + '</span></div>',
          '        <div>Driving: <span style="font-weight:bold;">' + Math.floor(target.totalDrivingMinutes) + ' mins</span></div>',
          '      </div>',
          '      <div class="wh-title" style="font-size: 11px; margin-top: 10px;">Top Driven Cars</div>',
          '      <div style="font-size:11px; margin-bottom: 12px; background: rgba(0,0,0,0.15); padding: 6px; border-radius: 4px; border:1px solid rgba(255,255,255,0.04);">' + favCarsText + '</div>',
          '      <div class="wh-title" style="font-size: 11px;">Modify Account Parameters</div>',
          '      <div style="display: flex; flex-direction: column; gap: 8px; margin-bottom: 10px;">',
          '        <div class="wh-row">',
          '          <input type="number" class="wh-input" id="whPlayerCashInput" value="' + target.cash + '" style="flex: 1;" />',
          '          <button class="wh-btn wh-btn-sec" id="whSetCash">Set Cash</button>',
          '        </div>',
          '        <div class="wh-row">',
          '          <input type="number" class="wh-input" id="whPlayerXpInput" value="' + target.xp + '" style="flex: 1;" />',
          '          <button class="wh-btn wh-btn-sec" id="whSetXp">Set XP</button>',
          '        </div>',
          '        <div class="wh-row">',
          '          <input type="number" class="wh-input" id="whPlayerLevelInput" value="' + target.level + '" style="flex: 1;" />',
          '          <button class="wh-btn wh-btn-sec" id="whSetLevel">Set Level</button>',
          '        </div>',
          '      </div>',
          '      <div class="wh-title" style="font-size: 11px;">Actions</div>',
          '      <div style="display: flex; gap: 6px;">',
          '        <button class="wh-btn wh-btn-sec" id="whSpectate" style="flex: 1;">Spectate</button>',
          '        <button class="wh-btn wh-btn-sec" id="whViewGarage" style="flex: 1;">View Garage</button>',
          '      </div>',
          '      <button class="' + banBtnClass + '" id="whBanPlayer" style="width: 100%; margin-top: 8px;">' + banBtnText + '</button>',
          '    </div>'
        );
      } else {
        whHtml.push(
          '    <div style="padding: 20px; text-align: center; color: rgba(255,255,255,0.4); font-size:12px;">Select a player from the list to inspect and moderate them</div>'
        );
      }
    }

    whHtml.push('  </div>', '</div>');

    content.innerHTML = css + whHtml.join('\n');

    // Register Tab event listeners
    document.getElementById('whTabWorld').addEventListener('click', function () {
      activeTab = 'world';
      renderWorldHub(data);
    });
    document.getElementById('whTabPlayers').addEventListener('click', function () {
      activeTab = 'players';
      renderWorldHub(data);
    });

    if (activeTab === 'world') {
      // Checkbox listener to disable/enable override price input
      var chk = document.getElementById('whOverrideEnabled');
      var priceInput = document.getElementById('whOverrideFuelPrice');
      chk.addEventListener('change', function () {
        priceInput.disabled = !chk.checked;
      });

      // Save fuel settings
      document.getElementById('whSaveFuel').addEventListener('click', function () {
        var gPrice = parseFloat(document.getElementById('whGlobalFuelPrice').value);
        var override = chk.checked;
        var oPrice = parseFloat(priceInput.value);

        SK.nui.post('phone:worldhub:setFuelSettings', {
          globalPrice: gPrice,
          nearestStationOverrideEnabled: override,
          nearestStationOverridePrice: oPrice
        }).done(function (result) {
          if (result && result.ok) {
            SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
              renderWorldHub(updatedData);
              // show flash success message
            });
          }
        });
      });

      // Apply loadscreen soundtrack
      document.getElementById('whApplyTune').addEventListener('click', function () {
        var selectedTune = document.getElementById('whSelectTune').value;
        SK.nui.post('phone:worldhub:setLoadscreenTune', selectedTune).done(function (result) {
          if (result && result.ok) {
            SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
              renderWorldHub(updatedData);
            });
          }
        });
      });

    } else {
      // Search text input listener
      var searchIn = document.getElementById('whPlayerSearch');
      searchIn.addEventListener('input', function () {
        playerSearchText = searchIn.value;
        // Re-render matching rows
        SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
          renderWorldHub(updatedData);
          var newSearch = document.getElementById('whPlayerSearch');
          newSearch.focus();
          newSearch.setSelectionRange(newSearch.value.length, newSearch.value.length);
        });
      });

      // Sort selection change
      var sortSel = document.getElementById('whPlayerSort');
      sortSel.addEventListener('change', function () {
        playerFilterMode = sortSel.value;
        renderWorldHub(data);
      });

      // Row click listener to inspect player
      var pRows = document.querySelectorAll('.wh-player-row');
      pRows.forEach(function (row) {
        row.addEventListener('click', function () {
          selectedPlayerId = parseInt(row.getAttribute('data-id'));
          banConfirmStep = 0; // reset ban confirm on switch
          renderWorldHub(data);
        });
      });

      if (target) {
        // Set Player cash
        document.getElementById('whSetCash').addEventListener('click', function () {
          var val = parseInt(document.getElementById('whPlayerCashInput').value);
          SK.nui.post('phone:worldhub:setPlayerCash', { targetId: target.id, amount: val }).done(function (result) {
            if (result && result.ok) {
              SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
                renderWorldHub(updatedData);
              });
            }
          });
        });

        // Set Player XP
        document.getElementById('whSetXp').addEventListener('click', function () {
          var val = parseInt(document.getElementById('whPlayerXpInput').value);
          SK.nui.post('phone:worldhub:setPlayerXp', { targetId: target.id, xp: val }).done(function (result) {
            if (result && result.ok) {
              SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
                renderWorldHub(updatedData);
              });
            }
          });
        });

        // Set Player Level
        document.getElementById('whSetLevel').addEventListener('click', function () {
          var val = parseInt(document.getElementById('whPlayerLevelInput').value);
          SK.nui.post('phone:worldhub:setPlayerLevel', { targetId: target.id, level: val }).done(function (result) {
            if (result && result.ok) {
              SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
                renderWorldHub(updatedData);
              });
            }
          });
        });

        // Spectate Player
        document.getElementById('whSpectate').addEventListener('click', function () {
          SK.nui.post('phone:worldhub:spectate', { targetId: target.id });
        });

        // View garage
        document.getElementById('whViewGarage').addEventListener('click', function () {
          SK.nui.post('phone:worldhub:getPlayerGarage', target.id).done(function (result) {
            if (result && result.ok) {
              // Generate vehicle list view inside simple floating overlay or alert
              var vehs = result.vehicles || {};
              var listHtml = [];
              for (var key in vehs) {
                var v = vehs[key];
                listHtml.push('<div><strong>' + v.displayName + '</strong> [' + v.plate + '] (Model: ' + v.modelName + ')</div>');
              }
              var message = listHtml.join('\n') || 'This player has no vehicles stored in their garage.';
              
              // Custom UI overlay display or simple alert
              alert('Garage for ' + target.name + ':\n\n' + message.replace(/<\/?[^>]+(>|$)/g, ""));
            }
          });
        });

        // Ban Player double confirmation flow
        document.getElementById('whBanPlayer').addEventListener('click', function () {
          if (banConfirmStep === 0) {
            banConfirmStep = 1;
            renderWorldHub(data);
          } else if (banConfirmStep === 1) {
            banConfirmStep = 2;
            renderWorldHub(data);
          } else if (banConfirmStep === 2) {
            SK.nui.post('phone:worldhub:banPlayer', target.id).done(function (result) {
              if (result && result.ok) {
                selectedPlayerId = null;
                banConfirmStep = 0;
                SK.nui.post('phone:worldhub:getState').done(function (updatedData) {
                  renderWorldHub(updatedData);
                });
              }
            });
          }
        });
      }
    }
  }

  // Register active spectating message state receiver
  window.addEventListener('message', function (event) {
    var data = event.data;
    if (data && data.type === 'worldhub:spectateUpdate') {
      // Can show NUI overlay indicator that we are spectating
      if (data.active) {
        SK.nui.post('phone:close'); // close tablet on spectate start
      }
    }
  });

  window.SKPhone.registerApp('Mechanic', function () {
    SK.nui.post('phone:mechanic:getState').done(function (data) {
      renderMechanic(data);
    });
  });

  window.SKPhone.registerApp('ControlWorld', function () {
    SK.nui.post('phone:worldhub:getState').done(function (data) {
      renderWorldHub(data);
    });
  });
})(window);
