// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RealDigital.sol";

/**
 * @title RealDigitalDefaultAccount
 * @dev Contrato que permite aos participantes trocarem sua carteira default.
 */
contract RealDigitalDefaultAccount is AccessControl {
    RealDigital private CBDC; // Referência ao contrato do Real Digital para validação de participantes.
    address private authority; // Autoridade do contrato. Adiciona carteiras default.
    address private admin; // Administrador do contrato. Permite trocar a autoridade.

    /**
     * @dev Mapping das contas default.
     *      Chave é o CNPJ8 do participante.
     */
    mapping(uint256 => address) private _defaultAccount;

    /**
     * @dev Modificador de método: somente participantes podem alterar suas carteiras default.
     */
    modifier onlyParticipant() {
        require(CBDC.verifyAccount(msg.sender), "Must be participant");
        _;
    }

    /**
     * @dev Construtor para instanciar o contrato.
     * @param token address: Endereço do Real Digital.
     * @param _authority address: Autoridade do contrato. Adiciona carteiras default.
     * @param _admin address: Administrador do contrato. Permite trocar a autoridade.
     */
    constructor(RealDigital token, address _authority, address _admin) {
        CBDC = token;
        authority = _authority;
        admin = _admin;
    }

    /**
     * @dev Adiciona a primeira carteira default para um participante.
     *      É permitido apenas para a autoridade.
     * @param cnpj8 uint256: CNPJ8 do participante.
     * @param wallet address: Carteira.
     */
    function addDefaultAccount(uint256 cnpj8, address wallet) public {
        require(msg.sender == authority, "Must be authority");
        _defaultAccount[cnpj8] = wallet;
    }

    /**
     * @dev Permite ao participante trocar sua carteira default.
     * @param cnpj8 uint256: CNPJ8 do participante.
     * @param newWallet address: Carteira.
     */
    function updateDefaultWallet(
        uint256 cnpj8,
        address newWallet
    ) public onlyParticipant {
        require(
            _defaultAccount[cnpj8] == msg.sender,
            "Must be current default account"
        );
        _defaultAccount[cnpj8] = newWallet;
    }

    /**
     * @dev Retorna a carteira default de um participante.
     * @param cnpj8 uint256: CNPJ8 do participante.
     * @return address Retorna o endereço da carteira default do participante.
     */
    function defaultAccount(uint256 cnpj8) public view returns (address) {
        return _defaultAccount[cnpj8];
    }
}
