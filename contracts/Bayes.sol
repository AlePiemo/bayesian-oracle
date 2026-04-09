// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Bayes is Pausable, AccessControl {
    
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;

    uint public P_CC_TRUE;
    uint public P_AD_TRUE;

    // Safety: blocca la scrittura se il rischio CC è > 60%
    uint public constant SAFETY_THRESHOLD = 600000; 
    // Guarantee: se il rischio AD è > 80%, il sistema deve reagire sospendendosi
    uint public constant CRITICAL_AD_THRESHOLD = 800000;

    mapping(string => mapping(bool => mapping(bool => uint))) public CPTS;

    // Eventi per il monitoraggio (Requirement: Guarantee/Response)
    event SafetyViolation(uint p_cc, address indexed user);
    event SystemPausedByOracle(uint p_ad);

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }

    //Configurazione (Solo Admin)

    function setPriors(uint p_cc_true, uint p_ad_true) public onlyRole(ADMIN_ROLE) {
        P_CC_TRUE = p_cc_true;
        P_AD_TRUE = p_ad_true;
    }

    function setCPT(string memory ev_name, uint ff, uint ft, uint tf, uint tt) public onlyRole(ADMIN_ROLE) {
        CPTS[ev_name][false][false] = ff;
        CPTS[ev_name][false][true]  = ft;
        CPTS[ev_name][true][false]  = tf;
        CPTS[ev_name][true][true]   = tt;
    }

    //logica inferenza (Requirement: Safety)

    function prior_cc(bool cc) private view returns (uint) {
        return cc ? P_CC_TRUE : (1000000 - P_CC_TRUE);
    }

    function prior_ad(bool ad) private view returns (uint) {
        return ad ? P_AD_TRUE : (1000000 - P_AD_TRUE);
    }

    function p_evidence(string memory ev_name, bool ev_value, bool cc, bool ad) private view returns (uint) {
        uint p_true = CPTS[ev_name][cc][ad];
        return ev_value ? p_true : (1000000 - p_true);
    }

    function infer_posteriors(
        string[] memory ev_names,
        bool[] memory ev_values,
        bool[] memory ev_observed
    ) public view returns (uint p_cc_true, uint p_ad_true, uint[2][2] memory joint_post) {
        uint[2][2] memory joint_unnorm;

        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                bool cc = (i == 1);
                bool ad = (j == 1);
                uint prob = prior_cc(cc) * prior_ad(ad);

                for (uint k = 0; k < ev_names.length; k++) {
                    if (!ev_observed[k]) continue;
                    // Divisione per 1M per evitare overflow
                    prob = (prob * p_evidence(ev_names[k], ev_values[k], cc, ad)) / 1000000;
                }
                joint_unnorm[i][j] = prob;
            }
        }

        uint Z = joint_unnorm[0][0] + joint_unnorm[0][1] + joint_unnorm[1][0] + joint_unnorm[1][1];
        require(Z != 0, "Normalizzazione fallita: Z=0");

        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                joint_post[i][j] = (joint_unnorm[i][j] * 1000000) / Z;
            }
        }

        p_cc_true = joint_post[1][0] + joint_post[1][1];
        p_ad_true = joint_post[0][1] + joint_post[1][1];
    }

    //Runtime Enforcement 

    function secureRecordUpdate(
        string[] memory ev_names, 
        bool[] memory ev_values, 
        bool[] memory ev_observed
    ) public whenNotPaused {
        
        (uint p_cc, uint p_ad, ) = infer_posteriors(ev_names, ev_values, ev_observed);

        // Se il rischio di credenziali compromesse è alto, blocca l'esecuzione.
        if (p_cc > SAFETY_THRESHOLD) {
            emit SafetyViolation(p_cc, msg.sender);
            revert("SAFETY ENFORCEMENT: Transazione negata per rischio compromissione elevato");
        }

        // Se il rischio di alterazione dato (AD) è critico, attiva il protocollo di emergenza.
        if (p_ad > CRITICAL_AD_THRESHOLD) {
            _pause(); 
            emit SystemPausedByOracle(p_ad);
        }
    }

    // Funzione per il ripristino post-allarme (Solo Admin)
    function adminReset() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}