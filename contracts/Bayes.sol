// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Bayes {

    uint public P_CC_TRUE;
    uint public P_AD_TRUE;

    // CPTS[ev_name][cc][ad]
    mapping(string => mapping(bool => mapping(bool => uint))) public CPTS;

    function setPriors(uint p_cc_true, uint p_ad_true) public {
        P_CC_TRUE = p_cc_true;
        P_AD_TRUE = p_ad_true;
    }

    function setCPT(
        string memory ev_name,
        uint ff,
        uint ft,
        uint tf,
        uint tt
    ) public {
        CPTS[ev_name][false][false] = ff;
        CPTS[ev_name][false][true]  = ft;
        CPTS[ev_name][true][false]  = tf;
        CPTS[ev_name][true][true]   = tt;
    }

    function prior_cc(bool cc) private view returns (uint) {
        return cc ? P_CC_TRUE : (1000000 - P_CC_TRUE);
    }

    function prior_ad(bool ad) private view returns (uint) {
        return ad ? P_AD_TRUE : (1000000 - P_AD_TRUE);
    }

    function p_evidence(
        string memory ev_name,
        bool ev_value,
        bool cc,
        bool ad
    ) private view returns (uint) {
        uint p_true = CPTS[ev_name][cc][ad];
        return ev_value ? p_true : (1000000 - p_true);
    }

    function infer_posteriors(
        string[] memory ev_names,
        bool[] memory ev_values,
        bool[] memory ev_observed
    )
    public view
    returns (uint p_cc_true, uint p_ad_true, uint[2][2] memory joint_post)
    {
        uint[2][2] memory joint_unnorm;

        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {

                bool cc = (i == 1);
                bool ad = (j == 1);

                uint prob = prior_cc(cc) * prior_ad(ad);

                for (uint k = 0; k < ev_names.length; k++) {
                    if (!ev_observed[k]) {
                        continue;
                    }
                    prob = prob * p_evidence(ev_names[k], ev_values[k], cc, ad);
                }

                joint_unnorm[i][j] = prob;
            }
        }

        uint Z = 0;
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                Z += joint_unnorm[i][j];
            }
        }

        require(Z != 0, "Errore: normalizzazione Z=0");

        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                joint_post[i][j] = joint_unnorm[i][j] * 1000000 / Z;
            }
        }

        p_cc_true = joint_post[1][0] + joint_post[1][1];
        p_ad_true = joint_post[0][1] + joint_post[1][1];
    }




}