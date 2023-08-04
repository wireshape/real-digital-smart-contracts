// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./RealDigital.sol";

/**
 * @title KeyDictionary
 * @dev Contrato que representa a consulta de carteiras de clientes. É um contrato de simulação de um diretório de informações.
 *      Este contrato será usado somente durante o piloto.
 */
contract KeyDictionary {
    /**
     * @dev Dados do cliente
     */
    struct CustomerData {
        uint256 taxId; // O CPF do cliente
        uint256 bankNumber; // O código da participante
        uint256 account; // A conta do cliente
        uint256 branch; // A agência do cliente
        address wallet; // A carteira do cliente
        bool registered; // Registrado ou não
        address owner; // A carteira do participante que inseriu o cliente
    }

    /**
     * @dev [Sugestão de implementação] Armazena uma requisição de troca de dono de chave.
     */
    struct KeyRequest {
        bytes32 key; // A chave do cliente.
        uint256 timestamp; // [Sugestão de implementação] verificacão de tempo de expiração da requisição.
        CustomerData data; // Os novos dados do cliente associado à chave.
    }

    RealDigital private CBDC; // Referência para o contrato de Real Digital.

    mapping(bytes32 => CustomerData) private customers; // Mapping de dados dos clientes.
    mapping(address => bytes32) private wallets; // Mapping das carteiras.
    mapping(uint256 => KeyRequest) private keyRequests; // Mapping das requisições de troca de dono de chave.

    /**
     * @dev Evento de solicitação de troca de dono de chave.
     * @param owner address: O atual dono da chave.
     * @param proposalId uint256: Id da proposta.
     * @param key bytes32: A chave.
     */
    event KeyRequested(address owner, uint256 proposalId, bytes32 key);

    /**
     * @dev Modificador de método: somente participantes podem executar o método.
     */
    modifier onlyParticipant() {
        require(CBDC.verifyAccount(msg.sender), "Must be participant");
        _;
    }

    /**
     * @dev Constrói uma instância do contrato e armazena o endereço do contrato do Real Digital.
     * @param token address: Endereço do contrato do Real Digital.
     */
    constructor(RealDigital token) {
        CBDC = token;
    }

    /**
     * @dev Adiciona os dados do cliente, vinculando à chave key.
     * @param key bytes32: A chave.
     * @param _taxId uint256: O CPF do cliente.
     * @param _bankNumber uint256: O ID do participante.
     * @param _account uint256: A conta do cliente.
     * @param _branch uint256: A agência do cliente.
     * @param _wallet address: A carteira do cliente.
     */
    function addAccount(
        bytes32 key,
        uint256 _taxId,
        uint256 _bankNumber,
        uint256 _account,
        uint256 _branch,
        address _wallet
    ) public onlyParticipant {
        customers[key] = CustomerData(
            _taxId,
            _bankNumber,
            _account,
            _branch,
            _wallet,
            false,
            msg.sender
        );
        wallets[_wallet] = key;
    }

    /**
     * @dev Retorna a carteira do cliente com base na sua chave key.
     * @param key bytes32: A chave cuja carteira está sendo buscada.
     */
    function getWallet(bytes32 key) public view returns (address) {
        return customers[key].wallet;
    }

    /**
     * @dev Retorna a chave do cliente com base na sua carteira.
     * @param wallet address: A carteira do cliente.
     */
    function getKey(address wallet) public view returns (bytes32) {
        return wallets[wallet];
    }

    /**
     * @dev Retorna todos os dados do cliente.
     * @param key bytes32: A chave do cliente solicitado.
     */
    function getCustomerData(
        bytes32 key
    ) public view returns (CustomerData memory) {
        return customers[key];
    }

    /**
     * @dev Atualiza os dados do cliente vinculado à chave key.
     *      Apenas o dono da carteira do participante ao qual o cliente vinculou sua chave pode alterar os dados por esta função.
     * @param key bytes32: A nova chave do cliente.
     * @param _taxId uint256: O novo CPF do cliente.
     * @param _bankNumber uint256: O novo ID do participante responsável pelo cliente.
     * @param _account uint256: A nova conta do cliente.
     * @param _branch uint256: A nova agência do cliente.
     * @param _wallet address: A nova carteira do cliente.
     */
    function updateData(
        bytes32 key,
        uint256 _taxId,
        uint256 _bankNumber,
        uint256 _account,
        uint256 _branch,
        address _wallet
    ) public onlyParticipant {
        require(
            customers[key].owner == msg.sender,
            "Only owner can update data"
        );
        customers[key] = CustomerData(
            _taxId,
            _bankNumber,
            _account,
            _branch,
            _wallet,
            false,
            msg.sender
        );
        wallets[_wallet] = key;
    }

    /**
     * @dev Requisita uma chave que pertence a outro participante.
     * @param key bytes32: A chave requisitada.
     * @param _taxId uint256: O CPF do cliente requisitante.
     * @param _bankNumber uint256: ID do participante responsável pelo cliente requisitante.
     * @param _account uint256: A conta do cliente requisitante.
     * @param _branch uint256: A agência do cliente requisitante.
     * @param _wallet address: A carteira do cliente requisitante.
     */
    function requestKey(
        bytes32 key,
        uint256 _taxId,
        uint256 _bankNumber,
        uint256 _account,
        uint256 _branch,
        address _wallet
    ) public onlyParticipant {
        require(!customers[key].registered, "Key already registered");
        require(customers[key].owner != msg.sender, "Cannot request own key");

        /**
         * @dev Cria uma proposta de troca de dono de chave.
         */
        uint256 proposalId = uint256(
            keccak256(abi.encodePacked(msg.sender, block.timestamp))
        );

        /**
         * @dev Armazena a proposta
         */
        keyRequests[proposalId] = KeyRequest(
            key,
            block.timestamp,
            CustomerData(
                _taxId,
                _bankNumber,
                _account,
                _branch,
                _wallet,
                false,
                msg.sender
            )
        );

        /**
         * @dev Emite o evento de solicitação de troca de dono de chave
         */
        emit KeyRequested(msg.sender, proposalId, key);
    }

    /**
     * @dev Autoriza a alteração de dados proposta pelo id proposalId para a chave key.
     * @param proposalId uint256: 	Id da proposta.
     * @param key bytes32: A chave cujos dados serão alterados.
     */
    function authorizeKey(
        uint256 proposalId,
        bytes32 key
    ) public onlyParticipant {
        require(
            keyRequests[proposalId].key == key,
            "ProposalId does not match key"
        );
        require(
            customers[key].owner == msg.sender,
            "Only owner can authorize key transfer"
        );

        /**
         * @dev [Sugestão de implementação] verificacão de tempo de expiração da proposta
         */
        require(
            keyRequests[proposalId].timestamp + 7 days > block.timestamp,
            "Proposal expired"
        );

        /**
         * @dev Atualiza os dados do cliente
         */
        customers[key] = keyRequests[proposalId].data;

        /**
         * @dev Atualiza o mapping de carteiras
         */
        wallets[keyRequests[proposalId].data.wallet] = key;
    }
}
