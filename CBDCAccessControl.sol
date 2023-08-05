// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title CBDCAccessControl
 * @dev Smart Contract responsável pela camada de controle de acesso para o Real Digital/Tokenizado.
 *      Suas principais funcionalidades são:
 *      - Determinar quais carteiras podem enviar/receber tokens.
 *      - Controlar os papeis de qual endereço pode emitir/resgatar/congelar saldo de uma carteira.
 */
abstract contract CBDCAccessControl is AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // Role que permite pausar o contrato.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Role que permite fazer o mint nos contratos de token.
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE"); // Role que permite habilitar um endereço.
    bytes32 public constant MOVER_ROLE = keccak256("MOVER_ROLE"); // Role que permite acesso à função move, ou seja, transferir o token de outra carteira.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // Role que permite acesso à função burn.
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE"); // Role que permite bloquear saldo de uma carteira, por exemplo para o swap de dois passos.

    /**
     * @dev Mapping das contas autorizadas a receber o token.
     */
    mapping(address => bool) private _authorizedAccounts;

    /**
     * @dev Evento de carteira habilitada.
     * @param member address: Carteira habilitada.
     */
    event EnabledAccount(address indexed member);

    /**
     * @dev Evento de carteira desabilitada.
     * @param member address: Carteira desabilitada.
     */
    event DisabledAccount(address indexed member);

    /**
     * @dev Constrói uma instância da contrato, armazenando os argumentos informados.
     * @param _authority address: Autoridade do contrato, pode fazer todas as operações com o token.
     * @param _admin address: Administrador do contrato, pode trocar a autoridade do contrato caso seja necessário.
     */
    constructor(address _authority, address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ACCESS_ROLE, _authority);
        _setupRole(MINTER_ROLE, _authority);
        _setupRole(BURNER_ROLE, _authority);
        _setupRole(MOVER_ROLE, _authority);
        _setupRole(FREEZER_ROLE, _authority);
        _setupRole(PAUSER_ROLE, _admin);

        bytes32 _adminHash = keccak256(abi.encodePacked(_admin));

        _setRoleAdmin(DEFAULT_ADMIN_ROLE, _adminHash);
    }

    /**
     * @dev Modificador que checa se tanto o pagador quanto o recebedor estão habilitados a receber o token.
     * @param from address: Carteira do pagador.
     * @param to address: Carteira do recebedor.
     */
    modifier checkAccess(address from, address to) {
        if (from != address(0)) {
            require(verifyAccount(from), "Sender is not enabled");
        } else if (to != address(0)) {
            require(verifyAccount(to), "Recipient is not enabled");
        }
        _;
    }

    /**
     * @dev Habilita a carteira a receber o token.
     * @param member address: Carteira a ser habilitada.
     */
    function enableAccount(address member) public {
        require(
            hasRole(ACCESS_ROLE, msg.sender),
            "Only the authority can enable account"
        );

        _authorizedAccounts[member] = true;
        emit EnabledAccount(member);
    }

    /**
     * @dev Desabilita a carteira.
     * @param member address: Carteira a ser desabilitada.
     */
    function disableAccount(address member) public {
        require(
            hasRole(ACCESS_ROLE, msg.sender),
            "Only the authority can disable account"
        );

        _authorizedAccounts[member] = false;
        emit DisabledAccount(member);
    }

    /**
     * @dev Checa se a carteira pode receber o token.
     * @param account address: Carteira a ser checada.
     * @return value bool: Retorna um valor booleano indicando a condição da carteira.
     */
    function verifyAccount(address account) public view returns (bool) {
        return _authorizedAccounts[account];
    }
}
