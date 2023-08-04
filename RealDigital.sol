// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./CBDCAccessControl.sol";

/**
 * @title RealDigital
 */
contract RealDigital is ERC20, CBDCAccessControl, Pausable {
    // Uso do SafeMath para prevenir overflow e underflow
    using SafeMath for uint256;

    /**
     * @dev Mapping das carteiras e respectivo valor congelado.
     */
    mapping(address => uint256) private frozenBalances;

    /**
     * @dev Evento emitido quando um valor de uma carteira é congelado.
     * @param wallet address: Carteira que teve o fundo congelado.
     * @param amount uint256: Quantidade congelada.
     */
    event FrozenBalance(address wallet, uint256 amount);

    /**
     * @dev Modifier para verificar se um endereço possui fundos suficientes.
     *      Usado no _beforeTokenTransfer.
     * @param from address: Carteira origem
     * @param amount uint256: Quantidade de tokens.
     */
    modifier checkFrozenBalance(address from, uint256 amount) {
        if (from != address(0)) {
            require(
                balanceOf(from) - frozenBalanceOf(from) >= amount,
                "RealDigital: insufficient balance"
            );
        }
        _;
    }

    /**
     * @dev Construtor do token do Real Digital.
     *      Invoca o construtor do ERC20 e dá permissão de autoridade para a carteira do BCB.
     * @param _name string: Nome do token: Real Digital.
     * @param _symbol string: Símbolo do token: BRL
     * @param _authority address: Carteira responsável por emitir, resgatar, mover e congelar fundos (BCB).
     * @param _admin address: Carteira responsável por administrar o controle de acessos (BCB).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _authority,
        address _admin
    ) ERC20(_name, _symbol) CBDCAccessControl(_authority, _admin) {}

    /**
     * @dev Função para pausar o token em casos necessários, bloqueando-o para todas as operações.
     */
    function pause() public whenNotPaused onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Função para despausar o token em casos necessários, desbloqueando-o para todas as operações.
     */
    function unpause() public whenPaused onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Gatilho executado sempre que é solicitada uma movimentação de token, inclusive na criação e destruição de tokens.
     *      Condições de chamada:
     *      - quando from é zero, amount tokens serão emitidos to.
     *      - quando to é zero, amount do from tokens serão destruídos.
     *      - from e to nunca serão simultaneamente zero.
     *      - from e to devem estar registrados como participantes.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override
        whenNotPaused
        checkFrozenBalance(from, amount)
        checkAccess(from, to)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Destrói um determinado valor da carteira.
     *      Veja {ERC20-burn}.
     */
    function burn(uint256 amount) public onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destrói amount tokens da account, deduzindo alllowance do executor. Olhe {ERC20-_burn} e {ERC20-allowance}.
     *      Requerimentos:
     *      - o executor deve possuir autorização de mover fundos da accounts de no mínimo o amount.
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public virtual whenNotPaused {
        uint256 decreasedAllowance = allowance(account, _msgSender()) - amount;
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /**
     * @dev Retorna o número de casas decimais utilizadas na representação do valor do token.
     *      Por exemplo, se decimals for igual a 2, um saldo de 505 tokens deve ser apresentado como 5.05 (505 / 10 ** 2).
     * @return value uint8: Retorna o número de casas decimais.
     */
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    /**
     * @dev Função para incrementar tokens parcialmente bloqueados de uma carteira.
     *      Somente quem possuir FREEZER_ROLE pode executar.
     * @param from address: Carteira origem.
     * @param amount uint256: Quantidade de tokens.
     */
    function increaseFrozenBalance(
        address from,
        uint256 amount
    ) public whenNotPaused onlyRole(FREEZER_ROLE) {
        frozenBalances[from] += amount;
        emit FrozenBalance(from, frozenBalances[from]);
    }

    /**
     * @dev Função para decrementar tokens parcialmente bloqueados de uma carteira.
     *      Somente quem possuir FREEZER_ROLE pode executar.
     * @param from address: Carteira origem.
     * @param amount uint256: Quantidade de tokens.
     */
    function decreaseFrozenBalance(
        address from,
        uint256 amount
    ) public whenNotPaused onlyRole(FREEZER_ROLE) {
        require(frozenBalances[from] >= amount, "Frozen balance is not enough");
        frozenBalances[from] -= amount;
        emit FrozenBalance(from, frozenBalances[from]);
    }

    /**
     * @dev Função para verificar o valor congelado de uma carteira.
     * @param wallet address: Carteira que se quer saber o valor congelado.
     * @return amount uint256: Quantidade congelada.
     */
    function frozenBalanceOf(address wallet) public view returns (uint256) {
        return frozenBalances[wallet];
    }

    /**
     * @dev Função para emitir tokens para as carteiras permitidas.
     * @param to address: Carteira destino.
     * @param amount uint256: Quantidade de tokens.
     */
    function mint(
        address to,
        uint256 amount
    ) public whenNotPaused onlyRole(MINTER_ROLE) {
        uint256 newAllowance = allowance(to, _msgSender()) + amount;
        _approve(to, _msgSender(), newAllowance);
        _mint(to, amount);
    }

    /**
     * @dev Função para mover tokens de uma carteira para outra.
     *      Somente quem possuir MOVER_ROLE pode executar.
     * @param from address: Carteira origem.
     * @param to address: Carteira destino.
     * @param amount uint256: Quantidade de tokens.
     */
    function move(
        address from,
        address to,
        uint256 amount
    ) public whenNotPaused onlyRole(MOVER_ROLE) {
        _transfer(from, to, amount);
    }

    /**
     * @dev Função para destruir tokens de uma carteira.
     *      Somente quem possuir MOVER_ROLE pode executar.
     * @param from address: Carteira origem.
     * @param amount uint256: Quantidade de tokens.
     */
    function moveAndBurn(
        address from,
        uint256 amount
    ) public whenNotPaused onlyRole(MOVER_ROLE) {
        _transfer(from, address(this), amount);
        _burn(address(this), amount);
    }

    /**
     * @dev Função para transferir tokens para uma carteira.
     * @param to address: Carteira destino.
     * @param amount uint256: Quantidade de tokens.
     * @return value bool: Retorna um valor booleano indicando se a operação foi bem-sucedida.
     */
    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            verifyAccount(_msgSender()),
            "Sender account is not authorized"
        );
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev Função para definir o valor como allowance de tokens da carteira.
     * @param spender address: Carteira para a qual o allowance será configurado.
     * @param amount uint256: Quantidade de tokens.
     * @return value bool: Retorna um valor booleano indicando se a operação foi bem-sucedida.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            verifyAccount(_msgSender()),
            "Sender account is not authorized"
        );
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Função para transferir tokens de uma carteira para outra.
     * @param from address: Carteira origem.
     * @param to address: Carteira destino.
     * @param amount uint256: Quantidade de tokens.
     * @return value bool: Retorna um valor booleano indicando se a operação foi bem-sucedida.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            verifyAccount(from) && verifyAccount(to),
            "Either from or to account is not authorized"
        );

        _transfer(from, to, amount);
        _approve(
            from,
            msg.sender,
            allowance(from, msg.sender).sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );

        return true;
    }

    /**
     * @dev Função para atomicamente decrementar o allowance concedido à carteira.
     * @param spender address: Carteira para a qual o allowance será decrementado.
     * @param subtractedValue uint256: Quantidade de tokens.
     * @return value bool: Retorna um valor booleano indicando se a operação foi bem-sucedida.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual override whenNotPaused returns (bool) {
        require(verifyAccount(_msgSender()), "Account is not authorized");
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender).sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Função para atomicamente incrementar o allowance concedido à carteira.
     * @param spender address: Carteira para a qual o allowance será incrementado.
     * @param addedValue uint256: Quantidade de tokens.
     * @return value bool: Retorna um valor booleano indicando se a operação foi bem-sucedida.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual override whenNotPaused returns (bool) {
        require(verifyAccount(_msgSender()), "Account is not authorized");
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender).add(addedValue)
        );
        return true;
    }
}
