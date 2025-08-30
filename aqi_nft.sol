// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AQIToken is ERC721, Ownable {
    using Strings for uint256;

    IERC20 public paymentToken;       // ERC20 token for minting fee
    uint256 public mintFee;           // fee per NFT
    uint256 private _nextTokenId;     // auto-incrementing token id
    string private _imageURL;         // static image URL
    string private _description;      // static description
    string private _externalBase;     // base external URL

    // Store datahash for each token
    mapping(uint256 => string) private _tokenDataHash;

    constructor(
        address initialOwner,
        address _paymentToken,
        uint256 _mintFee,
        string memory imageURL,
        string memory description,
        string memory externalBase
    ) ERC721("AQI Collectives", "AQI") Ownable(initialOwner) {
        paymentToken = IERC20(_paymentToken);
        mintFee = _mintFee;
        _imageURL = imageURL;
        _description = description;
        _externalBase = externalBase; // e.g. "https://mywebsite.com/nft/"
    }

    /// @notice Mint NFT by paying ERC20 fee and attach a datahash
    function mint(string memory datahash) external {
        require(
            paymentToken.transferFrom(msg.sender, address(this), mintFee),
            "Payment failed"
        );

        uint256 tokenId = _nextTokenId++;
        _tokenDataHash[tokenId] = datahash;

        _safeMint(msg.sender, tokenId);
    }

    /// @notice Return metadata JSON as base64-encoded data URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        ownerOf(tokenId);
        string memory name = string(abi.encodePacked("AQI Token #", tokenId.toString()));
        string memory description = _description;
        string memory image = _imageURL;
        string memory externalURL = string(abi.encodePacked(_externalBase, _tokenDataHash[tokenId]));

        // Build the raw JSON metadata
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name":"', name, '",',
                '"description":"', description, '",',
                '"image":"', image, '",',
                '"external_url":"', externalURL, '"',
            '}'
        );

        // Encode as base64 data URI
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    /// @notice Update mint fee
    function setMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
    }

    /// @notice Set payment ERC20 token
    function setPaymentToken(address token) external onlyOwner {
        paymentToken = IERC20(token);
    }

    /// @notice Withdraw collected ERC20 fees
    function withdraw(address to) external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No balance");
        require(paymentToken.transfer(to, balance), "Withdraw failed");
    }

    /// @notice Update static image URL
    function setImageURL(string memory url) external onlyOwner {
        _imageURL = url;
    }

    /// @notice Update static description
    function setDescription(string memory desc) external onlyOwner {
        _description = desc;
    }

    /// @notice Update external base URL
    function setExternalBase(string memory base) external onlyOwner {
        _externalBase = base;
    }
}
