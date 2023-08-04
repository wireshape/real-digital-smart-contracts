// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AddressDiscovery
 * @dev Smart Contract utilitário para facilitar a descoberta dos demais endereços de contratos na rede do Piloto RD.
 */
contract AddressDiscovery is AccessControl {
    /**
     * @dev Role de acesso, pertencente a autoridade do contrato.
     */
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

    /**
     * @dev Mapping do endereço dos contratos, a chave é o hash keccak256 do nome do contrato.
     */
    mapping(bytes32 => address) public addressDiscovery;

    /**
     * @dev Construtor para instanciar o contrato.
     * @param _authority address: Autoridade do contrato, pode atualizar os endereços dos contratos.
     * @param _admin address: Administrador, pode trocar a autoridade.
     */
    constructor(address _authority, address _admin) {
        _setRoleAdmin(ACCESS_ROLE, keccak256(abi.encodePacked(_authority)));
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ACCESS_ROLE, _authority);
    }

    /**
     * @dev Atualiza o endereço de um contrato, permitido apenas para a autoridade.
     * @param smartContract bytes32: Hash keccak256 do nome do contrato.
     * @param newAddress address: Novo endereço do contrato.
     */
    function updateAddress(bytes32 smartContract, address newAddress) public {
        require(
            hasRole(ACCESS_ROLE, msg.sender),
            "Only the authority can update addresses."
        );
        addressDiscovery[smartContract] = newAddress;
    }
}
