// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealDigital.sol";

/**
 * @title STR
 * @dev Este contrato que simula o STR. Por meio dele, os participantes autorizados podem emitir Real Digital.
 *      Para o piloto nenhuma validação é feita, bastando que o participante esteja autorizado.
 */
contract STR {
    RealDigital private CBDC; // Referência ao contrato do Real Digital para checar se o participante é autorizado.

    /**
     * @dev Constrói uma instância do contrato e armazena o endereço do Real Digital.
     * @param token address: Endereço do Real Digital.
     */
    constructor(RealDigital token) {
        CBDC = token;
    }

    /**
     * @dev Modificador de método: somente participantes podem executar a função.
     */
    modifier onlyParticipant() {
        require(CBDC.verifyAccount(msg.sender), "Must be participant");
        _;
    }

    /**
     * @dev Emite a quantidade de Real Digital informada em amount para a própria carteira executora desta função.
     * @param amount uint256: Quantidade a ser emitida (obs: lembrar das 2 casas decimais).
     */
    function requestToMint(uint256 amount) external onlyParticipant {
        CBDC.mint(msg.sender, amount);
    }

    /**
     * @dev Destrói a quantidade de Real Digital informada em amount da própria carteira executora desta função.
     * @param amount uint256: Quantidade a ser destruída (obs: lembrar das 2 casas decimais).
     */
    function requestToBurn(uint256 amount) external onlyParticipant {
        CBDC.burnFrom(msg.sender, amount);
    }
}
