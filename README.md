# Bayesian Oracle for Clinical Data Risk Assessment

Questo progetto implementa un oracle evidence-based ibrido (off-chain / on-chain) per la valutazione del rischio sui dati clinici, basato su una rete bayesiana.

Il sistema stima la probabilità di:
- Compromissione delle credenziali (CC)
- Alterazione del dato clinico (AD)

a partire da un insieme di evidenze osservate.

---

# 1. Struttura del progetto

Il progetto è composto da tre parti principali:

- **Smart contract (Solidity)**  
  Implementa il modello bayesiano e l’inferenza on-chain

- **Script di migrazione (Truffle)**  
  Esegue il deploy del contratto sulla blockchain locale

- **Script off-chain (JavaScript)**  
  Inizializza i parametri (prior e CPT) e invoca l’inferenza

---

# 2. Prerequisiti

Prima di eseguire il progetto, installare:

- Node.js
- Truffle
- Ganache

Installazione Truffle:

```bash
npm install -g truffle
```
---

# 3. Avvio del sistema

# 3.1. Avviare Ganache
Aprire Ganache e avviare una blockchain locale.

# 3.2. Compilare il contratto
Nel terminale, nella cartella del progetto:

```bash
truffle compile
```
# 3.3. Effettuare il deploy

```bash
truffle migrate --reset
```
Questo comando deploya lo smart contract sulla blockchain locale.

# 3.4. Eseguire lo script off-chain

```bash
truffle exec offchainOracle.js
```

---

# 4. Cosa fa lo script off-chain

Lo script esegue i seguenti passi:

  1. Imposta le probabilità a priori: P(CC) e P(AD)

  2. Imposta le tabelle di probabilità condizionata (CPT): PA (posizione anomala), PT (profilo temporale anomalo), CO (coerenza clinica) e DB (divergenza da backup)

  3. Invia questi valori allo smart contract

  4. Esegue l’inferenza bayesiana tramite la funzione: infer_posteriors(...)

  5. Stampa i risultati a terminale

  ---

# 5. Output

L'output è del tipo:

```JSON
  {
  "p_cc_true": "...",
  "p_ad_true": "...",
  "joint_post": [...]
}
```
dove p_cc_true è la probabilità di compromissione delle credenziali, p_ad_true è la probabilità di alterazione del dato e joint_post è la distribuzione congiunta P(CC, AD | evidenze).

---

# 6. Modello utilizzato

Il sistema implementa una rete bayesiana con:

# Variabili latenti

CC → Credenziali compromesse

AD → Alterazione del dato

# Evidenze

PA → Posizione anomala

PT → Profilo temporale anomalo

CO → Coerenza clinica

DB → Divergenza da backup

---

# 7. Interpretazione dei risultati

-Se P(CC) è alta → probabile compromissione delle credenziali

-Se P(AD) è alta → probabile alterazione dei dati

-Se entrambe sono alte → possibile attacco combinato

Il modello restituisce una valutazione probabilistica, non una decisione binaria.

---

# 8. Note tecniche

-Le probabilità sono scalate (fixed-point)

-L’inferenza viene eseguita on-chain

-Lo script off-chain gestisce inizializzazione e chiamate.