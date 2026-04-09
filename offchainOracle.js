const Bayes = artifacts.require("Bayes");

module.exports = async function (callback) {
  const c = await Bayes.deployed();

  function fromScaled(x) {
    return Number(x.toString()) / 1e6;
  }

  // CC = Credenziali Compromesse
  const P_CC_TRUE = 20000; //0.02
  //AD = Alterazione del Dato
  const P_AD_TRUE = 15000; //0.015 
  
  let accounts = await web3.eth.getAccounts();
  await c.setPriors(P_CC_TRUE,P_AD_TRUE,{from: accounts[0]});

  // ===== CPT_PA =====
  await c.setCPT("PA", 40000, 60000, 600000, 700000, { from: accounts[0] });

  // ===== CPT_PT =====
  await c.setCPT("PT", 50000, 70000, 550000, 650000, { from: accounts[0] });

  // ===== CPT_CO =====
  await c.setCPT("CO", 30000, 700000, 150000, 800000, { from: accounts[0] });

  // ===== CPT_DB =====
  await c.setCPT("DB", 20000, 600000, 50000, 700000, { from: accounts[0] });

  console.log("All data loaded correctly");

  // =============================================================
  // SEZIONE DI TEST MODIFICABILE
  // Cambia true/false qui sotto per testare il monitor
  // =============================================================
  const evidenze = {
    "PA": true,
    "PT": true,
    "CO": true,
    "DB": false
  };
  // =============================================================

  const ev_names = Object.keys(evidenze);
  const ev_values = Object.values(evidenze);
  const ev_observed = ev_names.map(() => true);

  console.log("\n--- Esecuzione Test Monitor ---");
  console.log("Input:", evidenze);

  // Reset automatico se il contratto era in pausa da un test precedente
  if (await c.paused()) {
    console.log("Sistema in pausa, eseguo adminReset...");
    await c.adminReset({ from: accounts[0] });
  }

  try {
    // Tentativo di chiamata alla funzione con monitor di sicurezza
    await c.secureRecordUpdate(ev_names, ev_values, ev_observed, { from: accounts[0] });
    console.log("Transazione RIUSCITA (Rischio accettabile)");
    
  } catch (error) {
    console.log("Transazione BLOCCATA dal monitor di sicurezza");
    
    // Mostra il messaggio di errore definito nel require/revert di Solidity
    const reason = error.reason || error.message;
    console.log("Messaggio di errore:", reason);

    // Verifica se è scattata la proprietà di Guarantee (Pause)
    if (await c.paused()) {
      console.log("⚠️ ATTENZIONE: Il contratto è entrato in stato PAUSED (Rischio critico)");
    }
  }

  // Visualizzazione inferenza finale (tua logica originale)
  const result = await c.infer_posteriors(ev_names, ev_values, ev_observed);
  console.log("\n--- Dati Inferenza ---");
  console.log({
    p_cc_true: fromScaled(result.p_cc_true),
    p_ad_true: fromScaled(result.p_ad_true)
  });

  callback();
};