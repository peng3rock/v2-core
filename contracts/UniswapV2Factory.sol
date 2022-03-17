pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair; // 存储交易对地址的 getPair[token0][token1] = pairAddress
    address[] public allPairs; // 数组保存所有pair 地址

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // 创建一个交易对 tokenA tokenB
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA); // token address排序确保 pair 唯一性
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode; // 获取部署 UniswapV2Pair 部署bytecode
        bytes32 salt = keccak256(abi.encodePacked(token0, token1)); // 部署需要的随机数，salt,保证部署前就确定部署后的地址。
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt) // 创建交易对合约
            //汇编语法 create2(v, n, p, s) 用 mem[p...(p + s)) 中的代码，在地址 keccak256(<address> . n . keccak256(mem[p...(p + s))) 上
            // 创建新合约、发送 v wei 并返回新地址
        }
        IUniswapV2Pair(pair).initialize(token0, token1); // 初始化 UniswapPair 合约中的状态变量 token0, token1
        getPair[token0][token1] = pair; // 赋值getPair
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length); // PairCreated event
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
