## Description stake task: 
Техническое задание (стейкинг)
Написать смарт-контракт стейкинга, создать пул ликвидности на uniswap в тестовой сети. 
Контракт стейкинга принимает ЛП токены, после определенного времени (например 10 минут) 
пользователю начисляются награды в виде ревард токенов написанных на первой неделе. 
Количество токенов зависит от суммы застейканных ЛП токенов (например 20 процентов). 
Вывести застейканные ЛП токены также можно после определенного времени (например 20 минут).
- Создать пул ликвидности
- Реализовать функционал стейкинга в смарт контракте
- Написать полноценные тесты к контракту
- Написать скрипт деплоя
- Задеплоить в тестовую сеть
- Написать таски на stake, unstake, claim
- Верифицировать контракт
Требования
- Функция stake(uint256 amount) - списывает с пользователя на контракт стейкинга ЛП токены в количестве amount, обновляет в контракте баланс пользователя
- Функция claim() - списывает с контракта стейкинга ревард токены доступные в качестве наград
- Функция unstake() - списывает с контракта стейкинга ЛП токены доступные для вывода
- Функции админа для изменения параметров стейкинга (время заморозки, процент)
### Description StakingConract:
Мой первый контракт стейкинга.
Контракт принимает LP токены пары созданной в (uniswap). 
В виде rewards пользователь за стейкинг получает вознаграждение в WETH токенах которыми owner конракта предварительно пополнил конракт стейка. Изначально, для rewards, я планировал реализовать функцию mint в WETH из контракта стейка и не оправлять WETH на контракт, но потом подумал что доп эмиссия WETH будет размывать существующую долю держателей токена, если только конечно дополнительно не сжигать излишне созданные в виде rewards WETH.    
Набор методов стандартный (stake, unstake, clime...), из доп опций: 
- 1 гибкая настройка по времени и процентной ставке в зависимости от суммы вклада, больше сумма выгодне ставка.  
- 2 автоматический пересчет процентной ставки (при частичном снятии или добавления к существующему стейку.
- 3 Автоматическая отправка процентных накоплений при удалении ставки и (или) частичном снятии с пересчетом (обнулением) времении и процентной ставки.  
- Interest rate (2000,1000) расчитывается в зависимости от суммы вклада в calculateInterestRate(_stake). Для тестов в remix и быстрого начисления ревордов достаточно в _timeMinutes передать 1 min, и перерасчет будет происходить поминутно в зависимости от суммы вклада. 
- В функции calculateReward исп 1 minutes c целью быстрых тестов, более быстрого снятия ревордов и также снятия всей или части суммы вклада (можно указать более короткий или долгий период 1 hour, или увеличить freezeTime на 60(1час)). Параметры функции calculateReward() можно настроить так как будет удобно, добавить разные варианты расчета ставок, период начисления, добавить структуру с stakeholder(ами) и передавать разные ставки в зависимости от логики начисления rewards, и тд.    
```
пример расчетов по ставкам:
(базовая ставка 2000, повышенная 1000)
ставка 1LP, rate 2000, reward за 1 мин = 0.0005 weth в мин (0.001 2 мин и т д). 
ставка 10LP, rate 2000, reward за 1 мин =  0.005weth в мин. 
ставка 50LP, rate 1000, reward за 1 мин = 0.05 weth. (при rate 2000 = 0,025weth мин)
```
#### Token contract address (Rinkiby): 

- StakinContract (1 min freezTime) = '0xc1B59A9f029D11f1EDAE92113CeBEc46C9F9352D'
https://rinkeby.etherscan.io/address/0xc1B59A9f029D11f1EDAE92113CeBEc46C9F9352D#code

- StakinContract (60 min freezTime) = '0x9A9a5ee5B74388247c072Ff37A37a1De019E98A1'
https://rinkeby.etherscan.io/address/0x9A9a5ee5B74388247c072Ff37A37a1De019E98A1#code

- Factory https://rinkeby.etherscan.io/address/0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f#readContract



- LP(UNI-V2): '0xF4927988BB35a7C0469C183f0e29adC8B16f0878'
https://rinkeby.etherscan.io/address/0xF4927988BB35a7C0469C183f0e29adC8B16f0878

- WETH rewardsAddress = '0xaa907E805779bf0Cd18B26f60D1AD5544140298e'
https://rinkeby.etherscan.io/address/0xaa907E805779bf0Cd18B26f60D1AD5544140298e#code

- first token: 
https://rinkeby.etherscan.io/token/0xcd61492203af21301dcc53b4f042998df65d128e

- second token:
https://rinkeby.etherscan.io/token/0xcb572d9fbc6bcc559420c7f759ee016c80823ccc

#### Connect to Uniswap: 
- docs.uniswap: 
https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02    
https://docs.uniswap.org/protocol/V1/guides/connect-to-uniswap:

- Factory Address rinkeby UniswapV2Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
- Router Address rinkeby UniswapV2Router02:  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
- код роутер https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol
- как начисляются LP токены за наполнение пула эфиром и своим токеном:
https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/UniswapV2Router02.sol#L42 
- Wrapped ETH (WETH) 0xe1686F0785008f01f5fAFcf34458B4a3049fBBdF 

- тестовый Uniswap:  https://app.uniswap.org/#/swap?chain=rinkeby

Учебные:    
- Fork and deploy Uniswap (Remix):
https://medium.com/@maxime.atton/fork-uniswap-v2-smart-contracts-ui-on-remix-e885d6cea176
- как добавить ликвидность на uniswap:
https://medium.com/singularitydao/how-to-add-liquidity-on-uniswap-d658ca935d6d
- Программирование DeFi: Uniswap. 
Часть 1 https://habr.com/ru/post/572034/
Часть 2 https://habr.com/ru/post/572126/
- Forking from mainnet: 
https://hardhat.org/hardhat-network/guides/mainnet-forking.html
- Справочник по сети Hardhat: 
https://hardhat.org/hardhat-network/reference/#initial-state
- Протокол Uniswap V2:
https://docs.uniswap.org/protocol/V2/introduction
https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/quick-start
https://github.com/Uniswap/v2-core
- SDK Uniswap V3:
https://docs.uniswap.org/sdk/introduction

#### All packages:
```
yarn init 
yarn add --dev hardhat 
yarn add --dev @nomiclabs/hardhat-ethers ethers 
yarn add --dev @nomiclabs/hardhat-waffle ethereum-waffle chai
yarn add --save-dev @nomiclabs/hardhat-etherscan
yarn add install dotenv 
yarn add --dev solidity-coverage 
yarn add --dev hardhat-gas-reporter 
yarn add --dev hardhat-gas-reporter
yarn add --dev hardhat-contract-sizer
```
#### Main command:
```
npx hardhat 
npx hardhat run scripts/file-name.js
npx hardhat test 
npx hardhat coverage
npx hardhat run --network localhost scripts/deploy.js
npx hardhat run scripts/deploy.js --network rinkiby
npx hardhat verify <contract_address> --network rinkiby
npx hardhat verify --constructor-args scripts/arguments.js <contract_address> --network rinkiby
npx hardhat verify --constructor-args scripts/arguments.js <conract_address> --network rinkiby
yarn run hardhat size-contracts 
yarn run hardhat size-contracts --no-compile
```
#### About fork unswap: 

- 1 вариант: 
Залить на тестовую сеть свой UniswapV2 инструкция: 
https://medium.com/@maxime.atton/fork-uniswap-v2-smart-contracts-ui-on-remix-e885d6cea176

UniswapV2Factory
https://rinkeby.etherscan.io/address/0x6ab3ea7427d63f3c97c898de9d84c65ec4c4be4f
UniswapV2Router02
https://rinkeby.etherscan.io/address/0x41bdf3dfddaec79e2b3d32636e0575a8eb700aa7

Pool Address: 0x88aade4e55c04e1d2f6b9ad400a4f4eb45942ea7 BLR/SSSR UniswapV3Factory (в проекте не исп)

- 2 вариант, Fork основной сети: 
Тестировать взаимодействие с существующими в сети контрактами можно через форк. Оверрайднуть дефолтное поле networks.hardhat. И вы сможете работать со стейтом, который был на N блоке, а это значит, что на этом блоке должны быть смарты UniswapV2. https://hardhat.org/hardhat-network/guides/mainnet-forking.html.

На стороне JS, когда мы пишем тесты, то hardhat поднимает локальную ноду. По сути в момент тестирования выполняются два процесса: процесс самой ноды и nodejs, выполняющая тесты. На локальной ноде поднимается rpc endpoint, который принимает json-объекты с методами и параметрами. Важно понимать, что ethers.js под капотом создает эти json-объекты и создает промис с вызовом этой rpc.

https://eth.wiki/json-rpc/API
view, pure functions, которые только читают сторадж контракта, вызываются через eth_call
обычные функции без модификатора, которые не только читают, а еще и изменяют стейт, вызываются через eth_sendTransaction

В тестах ethers составляет эти rpc-запросы под капотом и соответсвенно поэтому, eth_call вернет то, что прочитал в сторадже, а eth_sendTransaction вернет объект самой транзакции.

В первом задании был момент, когда функция transfer на ERC20  токене возвращает bool, результат вызова этой функции можно получить только в ответе на внутреннее сообщение, т.е. если какой-то другой контракт в своем коде вызовет функции transfer на контракте токена. Т.е. результат работы функций меняющих стейт доступен только в рантайме самой EVM(на уровне контрактов), которая выполняет транзакцию.

Также hardhat нода поддерживает кастомные rpc методы для тестирования, например 
await network.provider.send("evm_increaseTime", [seconds]);
await network.provider.send("evm_mine");
Эти два метода позволяют увеличить время следующего блока на seconds.
Еще можно использовать evm_setNextBlockTimestamp, для того чтобы засетить какое-либо точнее unix время.

Прошу прочитать про provider'a и signer'а в библиотеке ethers.js и вообще посмотреть какие функции там есть.
https://docs.ethers.io/v5/api/signer/ 
https://docs.ethers.io/v5/api/providers/provider/

````
https://hardhat.org/hardhat-network/guides/mainnet-forking.html
hardhat: {
    forking: { 
    url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
    blockNumber: 12883802
    } 
},
// npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/<key> --fork-block-number 12883802
```
#### Testing report   
