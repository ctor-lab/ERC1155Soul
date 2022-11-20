// SPDX-License-Identifier: MIT
// Creator: Ctor Lab (https://ctor.xyz)

pragma solidity >=0.8.0;

import "solmate/src/utils/SSTORE2.sol";


abstract contract ERC1155Soul {

    uint256 private _batchIndex;
    mapping(uint256 => address) private _batchDataStorage;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    error NotImplemented();
    error BalanceQueryForZeroAddress();
    error InputLengthMistmatch();
    error ExceedBatchSize();


    function uri(uint256 id) public view virtual returns (string memory);

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _batchSize() internal view virtual returns (uint256) {
        return 500;
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        return _startTokenId() + _batchIndex * _batchSize();
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        revert NotImplemented();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        revert NotImplemented();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        revert NotImplemented();
    }


    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        if(account == address(0)) {
            revert BalanceQueryForZeroAddress();
        }
        uint256 batch = (id - _startTokenId()) / _batchSize();
        uint256 offset = ((id - _startTokenId()) % _batchSize()) * 20;
        bytes memory data = SSTORE2.read(
            _batchDataStorage[batch]
            , offset, offset + 20
        );

        address owner;
        assembly {
            owner := mload(add(data,20))
        } 
        if(account == owner) {
            return 1;
        } else {
            return 0;
        }
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        if(accounts.length != ids.length) {
            revert InputLengthMistmatch();
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);
        unchecked {
            for (uint256 i = 0; i < accounts.length; ++i) {
                batchBalances[i] = 0;//balanceOf(accounts[i], ids[i]);
            }   
        }
        return batchBalances;
        
    }


    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }


    function _mint(
        address[] memory tos
    ) internal virtual {
        uint256 next = _nextTokenId();
        if(tos.length > _batchSize()) {
            revert ExceedBatchSize();
        }

        bytes memory buffer;
        assembly {
            buffer := tos
        }

        require(next + (tos.length - 1) > next );//no overflow    
        unchecked {
            for (uint256 i = 0; i < tos.length; i++) {
                address owner = tos[i];
                bytes32 ownerBytes = bytes32(bytes20(owner));
                assembly {  
                    mstore(add(add(buffer, mul(i, 20)),32), ownerBytes)
                } 
                    
                emit TransferSingle(msg.sender, address(0), owner, next + i, 1);
            }    
        }
        uint256 bufferLength = tos.length * 20;
        assembly {  
            mstore(buffer, bufferLength)
        } 

        _batchDataStorage[_batchIndex] = SSTORE2.write(
            buffer
        );
        _batchIndex++;
    }
}
