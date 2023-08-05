// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealDigital.sol";

/**
 * @title RealDigitalEnableAccount
 * @dev Contrato que permite ao participante habilitar outras carteiras de sua propriedade.
 */
contract RealDigitalEnableAccount {
    RealDigital private accessControlAddress; // Referência ao contrato do Real Digital para validação de participantes.
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev Constrói uma instância do contrato e armazena o endereço do contrato do RealDigital, responsável pelas
     *      verificações de controle de acesso.
     * @param _accessControlAddress address: Endereço do contrato de controle de acesso
     */
    constructor(address _accessControlAddress) {
        accessControlAddress = RealDigital(_accessControlAddress);
    }

    /**
     * @dev Habilita uma nova carteira para o participante.
     *      Qualquer carteira previamente habilitada para o participante pode habilitar outras carteiras.
     * @param member address: Novo endereço do participante.
     */
    function enableAccount(address member) public {
        require(
            accessControlAddress.verifyAccount(msg.sender),
            "Must be participant"
        );
        accessControlAddress.enableAccount(member);
    }

    /**
     * @dev Desabilita a própria carteira que executou a função.
     */
    function disableAccount() public {
        require(
            accessControlAddress.verifyAccount(msg.sender),
            "This address is already disabled"
        );
        accessControlAddress.disableAccount(msg.sender);
    }
}
