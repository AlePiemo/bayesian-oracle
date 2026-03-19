const Bayes = artifacts.require("Bayes");

module.exports = async function (callback) {
  const c = await Bayes.deployed();

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
  console.log(`P_CC_TRUE: ${ (await c.P_CC_TRUE()).toString() }, P_AD_TRUE: ${ (await c.P_AD_TRUE()).toString() }`);
  for (const ev of ["PA", "PT", "CO", "DB"]) {
      console.log(`${ev}:`, [
          [ (await c.CPTS(ev, false, false)).toString(), (await c.CPTS(ev, false, true)).toString() ],
          [ (await c.CPTS(ev, true, false)).toString(),  (await c.CPTS(ev, true, true)).toString() ]
      ]);
    }


  const result = await c.infer_posteriors(["PA","PT","CO","DB"], [true,false,false,false], [true,true,false,false]);
  console.log({ 
    p_cc_true: result.p_cc_true.toString(), 
    p_ad_true: result.p_ad_true.toString(), 
    joint_post: result.joint_post.map(row => row.map(cell => cell.toString())) 
});


  callback();
};
