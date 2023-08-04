// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealDigital.sol";

/**
 * @title RealTokenizado
 * @dev Implementação do contrato do Real Tokenizado (DVt e MEt).
 *      Este contrato herda do Real Digital e todas as funções implementadas.
 */
contract RealTokenizado is RealDigital {
    string public participant; // String que representa o nome do participante.
    uint256 public cnpj8; // Uitn256 que representa o número da instituição.
    address public reserve; // Carteira de reserva da instituição participante.

    /**
     * @dev Construtor do token do Real Tokenizado.
     *      Invoca o construtor do ERC20 e dá permissão de autoridade para a carteira do BCB.
     * @param _name string: Nome do token: Real Tokenizado (Instituiçâo).
     * @param _symbol string: Símbolo do token: BRL.
     * @param _authority address: Carteira responsável por emitir, resgatar, mover e congelar fundos (BCB).
     * @param _admin address: Carteira responsável por administrar o controle de acessos (BCB).
     * @param _participant string: Identificação do participante como string.
     * @param _cnpj8 uint256: Primeiros 8 digitos do CNPJ da instituição.
     * @param _reserve address: Carteira de reserva da instituição.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _authority,
        address _admin,
        string memory _participant,
        uint256 _cnpj8,
        address _reserve
    ) RealDigital(_name, _symbol, _authority, _admin) {
        participant = _participant;
        cnpj8 = _cnpj8;
        reserve = _reserve;
    }

    /**
     * @dev Função para atualizar a carteira de reserva do token.
     *      A carteira de reserva é usada pelo DvP.
     * @param newReserve Carteira da autoridade (Instituição).
     */
    function updateReserve(
        address newReserve
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        reserve = newReserve;
    }
}
