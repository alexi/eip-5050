# Willies

Slap or be slapped. That is the question in this game of passion and violence, played on the ultimate world stage. The blockchain.


                                                                              /&&&%%%&&&&&&&.                           
                                                                            /%&@&%&ҹ%%%%&&&&&@.                         
                                                                           /%&&%&%%ҹҹ%ҹ%%&&%&&@                         
                                                                           ҹ(%%ҹҹҹҹҹҹҹ%ҹҹҹ%&&&&                         
                                                                           (ҹҹҹ((ҹҹҹ(ҹҹ(ҹ%%%&&%                         
                                                                           (((ҹ✶((//(((ҹҹҹ%%&&                          
                                                                           .((((✶///////(((ҹҹ%                          
                                                                            ҹ((ҹҹ/✶///✶✶//(ҹҹҹ                          
                                                                            ҹҹҹ((/✶✶/✶✶✶✶// .,.                         
                                                               ,✶✶✶✶✶/,✶   (@@&ҹ(/✶.         (&                         
                                                              ✶✶✶✶✶✶✶(,✶,%%&%&         &%%%%&&&&                        
                                                            ,,✶✶✶,,,✶/,/&%ҹҹ%     ,%%%&&%&&&&&&&&/                      
                                                             ✶✶✶✶✶✶,✶✶/ҹҹҹ&%, ✶&&&%%%&&&&&&&&&&&&&✶                     
                                                      ✶(ҹҹ%(%✶,,,,,✶✶/ҹҹҹ%@%%%&&&&&%%%&&&&&&&&&&&&                      
                                                (ҹҹ%%&%%%%&%%%&&%%&(✶@%/&%&@&%&&&&&&&%%&&&&&&&&&&&                      
                                           (ҹ%%%%%%%%%&%%%&%%&&%%&&&&@&@@&%%@&&&&&&&&&%&&%%&&&&&&&                      
                                     .ҹҹ%%%%%%%%%%%%%%%%@&&%%%%%%%&&&@%%&&&@%&&&&&%%%&%%&%%&&@&@@@                      
                                 %ҹ%%%%%%%%%%%%%&&&&&&&&&&&%%&&&%%%&&&&&&%%&&&&&&%&%%%%&&&&&&&&@&&                      
                            ✶  %%%%%%%%%%%&&&&&&&&%%,    ✶%%%&&%%&%&&&%%%&&&&&%%%%&%&&&&&&&&&&&@@@                      
         ✶✶/✶✶✶✶✶✶✶✶✶✶✶✶✶✶/✶/✶, ✶%&&&&&&&&&&/             %&&%%%&&&&%%&&&%%%%%%&%&&&&&&&&&&&&&&@@✶                      
         ✶✶✶✶,✶✶✶✶✶✶✶,✶✶✶✶//(((,✶&&&&&                    &&%%%%%ҹ%%&&&&%%&%%%%%&&&&&&&&&&&&@@@@&                       
           ..       ✶✶/✶✶✶/((    &&                       %&&%&%&%%%%%%%%%%%&&&&&&&&&&&&&@@&@@@@ҹ,                      
                      .                                   (&&&%%%%%%%%%%&&&&&&&&&&&&&&@&&&&&@@@&&%%%%%%/                
                                                           &&&%%&&&%&%&&&&&&&&&&@@&&&&&@&&&&&&&&%%%%ҹҹ%ҹҹ%ҹҹҹҹ          
                                                          %&&&&&&&&&&&&&&&@@@&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%ҹ       
                                                          %@@@&&@&@&@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%&%%%%&&&&&&&%     
                                                         &&%&@@@&&&&@&%&&&&&&&&%&&&&&&&&&&%&&&&&&&&%%ҹҹ%&&&&&&&&&&&%    
                                                        %&&&&%&&&&&&&&&&&&%%%&%&%&%&&&&&&&&&&@&&&@&%ҹ%&&&&&&&&&&&&&&    
                                                       ✶%%&&&&&&&&&@@&&&&&&%&&&&&&&&%&%&&&&&&&&&&ҹ%&&&&&&&&&&&&&&&&&&   
                                                       &%%&&%&&%%&%%%&%%&%%&&&&&&&&&%%&%&&@&&&&&&&&&&%%&&&&%%&&&&&&&&   
                                                      /&&&&%%%%%%%%%%%%&&%%%%%%%&&&%&&&&&&&&&&&&&&@&&&&%%&&&&ҹ,.        
                                                      &&&&&%%%%%%%%&&&%%%%%&%%%%&&&&&&&%&&&&&&&&&&&&&@&%                
                                                      &%%%%%%%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@&&@@&&               
                                                      %%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&@@&&&&@&&%             
                                                      ҹ%%%%%%&&&&&&&&&&&&&&&&&&@@&&&&&&&&&&&&&@@@&&&&&@&&&&&            
                                                       %%%&%&&&&&&&&@&@@@&@@@&@@&&&&&&&&&&&&&@&&&&&&&@&&&&&,            
                                                       &%&&&&&&&&&&&@@&@@&&@&@@&&&&&&&&&&&&&&&@&&&&&&&&&                


## SlapState

The `SlapState` contract provides the global slapping game state.

```solidity
interface ISlapState {
    enum TokenSlapState {
        DEFAULT,
        SLAPPED,
        WINNER,
        DEAD
    }

    struct TokenStats {
        uint256 strength;
        TokenSlapState state;
    }

    function registerToken(address _contract, uint256 tokenId) external;

    function get(address _contract, uint256 tokenId)
        external
        view
        returns (TokenStats memory);

    function getStrength(address _contract, uint256 tokenId)
        external
        view
        returns (uint256);

    function getState(address _contract, uint256 tokenId)
        external
        view
        returns (TokenSlapState);
}
```

## SlappedApes

BAYC joins the frey with a proxy contract set by the original contract `owner()`. Both `Willis.sol` and `SlapState.sol` implement the [proxy-compatible version of `ERCxxxx`](https://github.com/alexi/action-protocol/tree/main/contracts/proxy). While the deployed version of this protocol will use a modified version of [ERC-1820](https://eips.ethereum.org/EIPS/eip-1820#erc-1820-registry-smart-contract) that allows [ERC-173](https://eips.ethereum.org/EIPS/eip-173) contract owners to call `setManager()`, a simpler `ERCxxxxProxyRegistry` is used for demonstration purposes.

## Configurable State Read-Targets

Any contract implementing the `ISlapState` interface can be used for slapping, but for contracts that change their render based on their slap state a single contract needs to be set for `tokenURI` reads.

Willies and SlappedApes both allow token holders to set their own state read-target, with a global default as failover.

```solidity
    /// Any state controller can be used for actions, but tokenURI
    /// reads need a single default.
    address defaultStateController;

    /// Allow token holders to set custom default state controller for
    /// tokenURI reads.
    mapping(uint256 => address) tokenStateController;
```