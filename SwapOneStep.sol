// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealDigital.sol";
import "./RealTokenizado.sol";

/**
 * @title SwapOneStep
 * @dev Este contrato implementa a troca de Real Tokenizado entre dois participantes distintos.
 *
 *      A troca destrói Real Tokenizado do cliente pagador, transfere Real Digital do participante pagador para o
 *      participante recebedor e emite Real Tokenizado para o cliente recebedor.
 *
 *      Todos os passos dessa operação de swap são realizados em apenas uma transação.
 */
contract SwapOneStep {
    RealDigital private CBDC; // Referência ao contrato para que seja efetuada a movimentação de Real Digital.

    /**
     * @dev Evento de swap executado.
     * @param senderNumber uint256: O CNPJ8 do pagador.
     * @param receiverNumber uint256: O CNPJ8 do recebedor.
     * @param sender address: A carteira do pagador.
     * @param receiver address: A carteira do recebedor.
     * @param amount uint256: O valor que foi movimentado.
     */
    event SwapExecuted(
        uint256 senderNumber,
        uint256 receiverNumber,
        address sender,
        address receiver,
        uint256 amount
    );

    /**
     * @dev Constrói uma instância do contrato e armazena o endereço do contrato do Real Digital.
     * @param _CBDC address: Endereço do contrato do Real Digital.
     */
    constructor(RealDigital _CBDC) {
        CBDC = _CBDC;
    }

    /**
     * @dev Transfere o Real Tokenizado do cliente pagador para o recebedor.
     *      O cliente pagador é identificado pela carteira que estiver executando esta função.
     * @param tokenSender address: O endereço do contrato de Real Tokenizado do participante pagador.
     * @param tokenReceiver address: O endereço do contrato de Real Tokenizado do participante recebedor.
     * @param receiver address: O endereço do cliente recebedor.
     * @param amount uint256: O valor a ser movimentado.
     */
    function executeSwap(
        RealTokenizado tokenSender,
        RealTokenizado tokenReceiver,
        address receiver,
        uint256 amount
    ) public {
        tokenSender.burnFrom(msg.sender, amount);
        CBDC.move(tokenSender.reserve(), tokenReceiver.reserve(), amount);
        tokenReceiver.mint(receiver, amount);

        emit SwapExecuted(
            tokenSender.cnpj8(),
            tokenReceiver.cnpj8(),
            msg.sender,
            receiver,
            amount
        );
    }
}
