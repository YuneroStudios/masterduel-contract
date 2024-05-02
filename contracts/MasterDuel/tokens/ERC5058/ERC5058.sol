// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.18;

import {IERC5058} from "./IERC5058.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implementation ERC721 Lockable Token
 */
abstract contract ERC5058 is ERC721A, IERC5058 {
		constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}
    // Mapping from token ID to unlock time
    mapping(uint256 => uint256) public lockedTokens;

    // Mapping from token ID to lock approved address
    mapping(uint256 => address) private _lockApprovals;

    // Mapping from owner to lock operator approvals
    mapping(address => mapping(address => bool)) private _lockOperatorApprovals;

    /**
     * @dev See {IERC5058-lockApprove}.
     */
    function lockApprove(address to, uint256 tokenId) public virtual override {
        require(!isLocked(tokenId), "ERC5058: token is locked");
        address owner = ERC721A.ownerOf(tokenId);
        require(to != owner, "ERC5058: lock approval to current owner");

        require(
            _msgSenderERC721A() == owner ||
                isLockApprovedForAll(owner, _msgSenderERC721A()),
            "ERC5058: lock approve caller is not owner nor approved for all"
        );

        _lockApprove(owner, to, tokenId);
    }

    /**
     * @dev See {IERC5058-getLockApproved}.
     */
    function getLockApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        require(
            _exists(tokenId),
            "ERC5058: lock approved query for nonexistent token"
        );

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC5058-lockerOf}.
     */
    function lockerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        require(
            _exists(tokenId),
            "ERC5058: locker query for nonexistent token"
        );
        require(
            isLocked(tokenId),
            "ERC5058: locker query for non-locked token"
        );

        return _lockApprovals[tokenId];
    }

    /**
     * @dev See {IERC5058-setLockApprovalForAll}.
     */
    function setLockApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setLockApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC5058-isLockApprovedForAll}.
     */
    function isLockApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _lockOperatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC5058-isLocked}.
     */
    function isLocked(
        uint256 tokenId
    ) public view virtual override returns (bool) {
        return lockedTokens[tokenId] > block.timestamp;
    }

    /**
     * @dev See {IERC5058-lockExpiredTime}.
     */
    function lockExpiredTime(
        uint256 tokenId
    ) public view virtual override returns (uint256) {
        return lockedTokens[tokenId];
    }

    /**
     * @dev See {IERC5058-lock}.
     */
    function lock(uint256 tokenId, uint256 expired) public virtual override {
        require(
            _isLockApprovedOrOwner(_msgSenderERC721A(), tokenId),
            "ERC5058: lock caller is not owner nor approved"
        );
        require(
            expired > block.number,
            "ERC5058: expired time must be greater than current block number"
        );
        require(!isLocked(tokenId), "ERC5058: token is locked");

        _lock(_msgSenderERC721A(), tokenId, expired);
    }

    /**
     * @dev See {IERC5058-unlock}.
     */
    function unlock(uint256 tokenId) public virtual override {
        require(
            lockerOf(tokenId) == _msgSenderERC721A(),
            "ERC5058: unlock caller is not lock operator"
        );

        address from = ERC721A.ownerOf(tokenId);

        _beforeTokenLock(_msgSenderERC721A(), from, tokenId, 0);

        delete lockedTokens[tokenId];

        emit Unlocked(_msgSenderERC721A(), from, tokenId);

        _afterTokenLock(_msgSenderERC721A(), from, tokenId, 0);
    }

    /**
     * @dev Locks `tokenId` from `from`  until `expired`.
     *
     * Requirements:
     *
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Locked} event.
     */
    function _lock(
        address operator,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {
        address owner = ERC721A.ownerOf(tokenId);

        _beforeTokenLock(operator, owner, tokenId, expired);

        lockedTokens[tokenId] = expired;
        _lockApprovals[tokenId] = operator;

        emit Locked(operator, owner, tokenId, expired);

        _afterTokenLock(operator, owner, tokenId, expired);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`, but the `tokenId` is locked and cannot be transferred.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     *
     * Emits {Locked} and {Transfer} event.
     */
    function _safeLockMint(
        address to,
        uint256 tokenId,
        uint256 expired,
        bytes memory _data
    ) internal virtual {
        require(
            expired > block.number,
            "ERC5058: lock mint for invalid lock block number"
        );

        _safeMint(to, tokenId, _data);

        _lock(_msgSenderERC721A(), tokenId, expired);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the lock approvals for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ERC721A.ownerOf(tokenId);
        super._burn(tokenId);

        _beforeTokenLock(_msgSenderERC721A(), owner, tokenId, 0);

        // clear lock approvals
        delete lockedTokens[tokenId];
        delete _lockApprovals[tokenId];

        _afterTokenLock(_msgSenderERC721A(), owner, tokenId, 0);
    }

    /**
     * @dev Approve `to` to lock operate on `tokenId`
     *
     * Emits a {LockApproval} event.
     */
    function _lockApprove(
        address owner,
        address to,
        uint256 tokenId
    ) internal virtual {
        _lockApprovals[tokenId] = to;
        emit LockApproval(owner, to, tokenId);
    }

    /**
     * @dev Approve `operator` to lock operate on all of `owner` tokens
     *
     * Emits a {LockApprovalForAll} event.
     */
    function _setLockApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC5058: lock approve to caller");
        _lockOperatorApprovals[owner][operator] = approved;
        emit LockApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Returns whether `spender` is allowed to lock `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isLockApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        require(
            _exists(tokenId),
            "ERC5058: lock operator query for nonexistent token"
        );
        address owner = ERC721A.ownerOf(tokenId);
        return (spender == owner ||
            isLockApprovedForAll(owner, spender) ||
            getLockApproved(tokenId) == spender);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the `tokenId` must not be locked.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;
            require(!isLocked(tokenId), "ERC5058: token transfer while locked");
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
				super._afterTokenTransfers(from, to, startTokenId, quantity);
        // Revoke the lock approval from the previous owner on the current token.
				for (uint256 i = 0; i < quantity; i++) {
						uint256 tokenId = startTokenId + i;
						if (_lockApprovals[tokenId] != address(0)) {
								delete _lockApprovals[tokenId];
						}
				}
    }

    /**
     * @dev Hook that is called before any token lock/unlock.
     *
     * Calling conditions:
     *
     * - `owner` is non-zero.
     * - When `expired` is zero, `tokenId` will be unlock for `from`.
     * - When `expired` is non-zero, ``from``'s `tokenId` will be locked.
     *
     */
    function _beforeTokenLock(
        address operator,
        address owner,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {}

    /**
     * @dev Hook that is called after any lock/unlock of tokens.
     *
     * Calling conditions:
     *
     * - `owner` is non-zero.
     * - When `expired` is zero, `tokenId` will be unlock for `from`.
     * - When `expired` is non-zero, ``from``'s `tokenId` will be locked.
     *
     */
    function _afterTokenLock(
        address operator,
        address owner,
        uint256 tokenId,
        uint256 expired
    ) internal virtual {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC5058).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // @dev This empty reserved space is put in place to allow future versions to add new variables without shifting down
    // storage in the inheritance chain.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private __gap;
}
