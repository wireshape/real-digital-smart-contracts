// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealDigital.sol";
import "./RealTokenizado.sol";

/**
 * @title SwapTwoSteps
 * @dev Este contrato implementa a troca de Real Tokenizado entre dois participantes distintos.
 *      A troca destrói Real Tokenizado do cliente pagador, transfere Real Digital do participante pagador para o
 *      participante recebedor e emite Real Tokenizado para o cliente recebedor.
 *      A operação de swap implementada neste contrato é realizada em duas transações: uma de proposta e outra de aceite.
 */
contract SwapTwoSteps {
    RealDigital private CBDC; // Referência ao contrato para que seja efetuada a movimentação de Real Digital.

    /**
     * @dev Enumeração com as possíveis situações de uma operação de swap.
     */
    enum SwapStatus {
        PENDING, // Operação de _swap_ registrada, pendente de cancelamento ou execução.
        EXECUTED, // Operação de _swap_ executada.
        CANCELLED // Operação de _swap_ cancelada.
    }

    struct SwapProposal {
        RealTokenizado tokenSender; // O endereço do contrato de Real Tokenizado do participante pagador.
        RealTokenizado tokenReceiver; // O endereço do contrato de Real Tokenizado do participante recebedor.
        address sender; // O endereço da wallet do cliente pagador.
        address receiver; // O endereço da wallet do cliente recebedor.
        uint256 amount; // Quantidade de Reais a ser movimentada.
        SwapStatus status; // Situação atual da operação.
        uint256 timestamp;
    }

    uint256 private proposalCounter; // Número da última proposta.

    /**
     * @dev Mapping de propostas de swap.
     */
    mapping(uint256 => SwapProposal) public swapProposals;

    /**
     * @dev Evento de início do swap.
     * @param proposalId uint256: Id da proposta.
     * @param senderNumber uint256: CNPJ8 do pagador
     * @param receiverNumber uint256: CNPJ8 do recebedor
     * @param sender address: Endereço do pagador
     * @param receiver address: Endereço do recebedor
     * @param amount uint256: Valor
     */
    event SwapStarted(
        uint256 proposalId,
        uint256 senderNumber,
        uint256 receiverNumber,
        address sender,
        address receiver,
        uint256 amount
    );

    /**
     * @dev Evento de swap executado.
     * @param proposalId uint256: Id da proposta.
     * @param senderNumber uint256: CNPJ8 do pagador.
     * @param receiverNumber uint256: CNPJ8 do recebedor.
     * @param sender address: Endereço do pagador.
     * @param receiver address: Endereço do recebedor.
     * @param amount uint256: Valor
     */
    event SwapExecuted(
        uint256 proposalId,
        uint256 senderNumber,
        uint256 receiverNumber,
        address sender,
        address receiver,
        uint256 amount
    );

    /**
     * @dev Evento de swap cancelado.
     * @param proposalId uint256: Id da proposta.
     * @param reason string: Razão do cancelamento.
     */
    event SwapCancelled(uint256 proposalId, string reason);

    /**
     * @dev Evento de proposta expirada. A proposta expira em 1 minuto.
     * @param proposalId uint256: Id da proposta.
     */
    event ExpiredProposal(uint256 proposalId);

    /**
     * @dev Construtor para instanciar o contrato.
     * @param _CBDC address: Endereço do contrato do Real Digital.
     */
    constructor(RealDigital _CBDC) {
        CBDC = _CBDC;
        proposalCounter = 0;
    }

    /**
     * @dev Cria a proposta de swap.
     * @param tokenSender address: Endereço do contrato de Real Tokenizado do pagador.
     * @param tokenReceiver address: Endereço do contrato de Real Tokenizado do recebedor.
     * @param receiver address: Endereço do cliente recebedor.
     * @param amount uint256: Valor.
     */
    function startSwap(
        RealTokenizado tokenSender,
        RealTokenizado tokenReceiver,
        address receiver,
        uint256 amount
    ) public {
        proposalCounter += 1;
        swapProposals[proposalCounter] = SwapProposal({
            tokenSender: tokenSender,
            tokenReceiver: tokenReceiver,
            sender: msg.sender,
            receiver: receiver,
            amount: amount,
            status: SwapStatus.PENDING,
            timestamp: block.timestamp
        });

        emit SwapStarted(
            proposalCounter,
            tokenSender.cnpj8(),
            tokenReceiver.cnpj8(),
            msg.sender,
            receiver,
            amount
        );
    }

    /**
     * @dev Aceita a proposta de swap, executável apenas pelo recebedor.
     * @param proposalId uint256: Id da proposta.
     */
    function executeSwap(uint256 proposalId) public {
        SwapProposal storage proposal = swapProposals[proposalId];
        require(
            proposal.receiver == msg.sender,
            "Only the receiver can execute the swap."
        );
        require(
            proposal.status == SwapStatus.PENDING,
            "Cannot execute swap, status is not PENDING."
        );
        require(
            proposal.timestamp + 7 days > block.timestamp,
            "Proposal expired"
        );

        proposal.tokenSender.burnFrom(proposal.sender, proposal.amount);
        CBDC.move(
            proposal.tokenSender.reserve(),
            proposal.tokenReceiver.reserve(),
            proposal.amount
        );
        proposal.tokenReceiver.mint(proposal.receiver, proposal.amount);

        proposal.status = SwapStatus.EXECUTED;

        emit SwapExecuted(
            proposalId,
            proposal.tokenSender.cnpj8(),
            proposal.tokenReceiver.cnpj8(),
            proposal.sender,
            proposal.receiver,
            proposal.amount
        );
    }

    /**
     * @dev Cancela a proposta.
     *      Pode ser executada tanto pelo pagador quanto pelo recebedor.
     * @param proposalId uint256: Id da proposta
     * @param reason string: Razão do cancelamento
     */
    function cancelSwap(uint256 proposalId, string memory reason) public {
        SwapProposal storage proposal = swapProposals[proposalId];
        require(
            msg.sender == proposal.sender || msg.sender == proposal.receiver,
            "Only the sender or receiver can cancel the swap."
        );
        require(
            proposal.status == SwapStatus.PENDING,
            "Cannot cancel swap, status is not PENDING."
        );

        proposal.status = SwapStatus.CANCELLED;
        emit SwapCancelled(proposalId, reason);
    }
}
