// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// @creator: 0xmonas.eth
// @author: f

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Prompter is ERC721Enumerable, Ownable {
    using Strings for uint256;
    enum Status { Inactive, Private, Whitelist, Public }

    mapping (uint256 => string) private prompts;
    mapping (string => bool) public promptCheck;
    mapping (address => uint256) public promptCount;
    mapping (uint256 => uint256) public promptTimestamp;
    mapping (address => uint256) public whitelistCount;
    mapping (address => uint256) public privateCount;
    
    uint256 public price = 0.0069 ether;
    uint256 public wlPrice = 0.0042 ether;

    uint256 public maxPerWallet = 5;
    uint256 public maxPerWalletWL = 2;
    uint256 public maxPerWalletPrivate = 3;

    uint256 public maxSupply = 10000;
    uint256 public wlSupply = 1000;
    uint256 public privateSupply = 1260;

    bytes32 private _merkleRootWL;
    bytes32 private _merkleRootPrivate;

    Status public saleStatus;
    
    constructor() ERC721("Prompter II", "TPC") {
        saleStatus = Status.Inactive;
    }

    function mint(string memory _prompt) public payable {
        require(uint256(saleStatus) == 3, "Public sale isn't active.");
        require(promptCount[msg.sender] < maxPerWallet, "You can mint up to 5 tokens.");
        require(totalSupply() < maxSupply, "Sold out.");
        checkRequirements(price, _prompt);

        claimPrompt(_prompt, block.timestamp);
    }

    function mintWL(string memory _prompt, bytes32[] calldata _merkleProof) public payable {
        require(uint256(saleStatus) == 2, "Whitelist sale isn't active.");
        require(whitelistCount[msg.sender] < maxPerWalletWL, "You can mint up to 2 tokens.");
        require(totalSupply() < wlSupply + privateSupply, "WL ended.");
        require(MerkleProof.verify(_merkleProof, _merkleRootWL, keccak256(abi.encodePacked(msg.sender))), "You're not whitelisted.");
        checkRequirements(wlPrice, _prompt);

        whitelistCount[msg.sender] += 1;
        claimPrompt(_prompt, block.timestamp);
    }

    function mintPrivate(string memory _prompt, bytes32[] calldata _merkleProof) public {
        require(uint256(saleStatus) == 1, "Private sale isn't active.");
        require(privateCount[msg.sender] < maxPerWalletPrivate, "You can mint up to 3 tokens.");
        require(totalSupply() < privateSupply, "Private sale ended.");
        require(MerkleProof.verify(_merkleProof, _merkleRootPrivate, keccak256(abi.encodePacked(msg.sender))), "You don't have free mint pass.");
        checkRequirements(0, _prompt);

        privateCount[msg.sender] += 1;
        claimPrompt(_prompt, block.timestamp);
    }


    function checkRequirements(uint256 minPrice, string memory _prompt) internal {
        require(bytes(_prompt).length < 422, "Max length 421 // Only base64 characters");
        require(promptCheck[_prompt] == false, "This prompt claimed.");
        require(msg.value >= minPrice, "Art isn't expensive.");
    }

    function claimPrompt(string memory _prompt, uint256 _timestamp) internal {
        promptCheck[_prompt] = true;
        prompts[totalSupply() + 1] = _prompt;
        promptCount[msg.sender] += 1;
        promptTimestamp[totalSupply() + 1] = _timestamp;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function adminMint(string memory _prompt) public onlyOwner {
        claimPrompt(_prompt, block.timestamp);
    }

    function buildImage(string memory _prompt) internal pure returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000">',
                    '<style>@import url(https://fonts.googleapis.com/css2?family=Inter+Tight:ital,wght@1,500&display=swap);span{fill:#111;font-family:"Inter Tight";font-size:50px;overflow-wrap:break-word;line-height:100%}foreignObject{padding:45px}</style>',
                    '<svg overflow="visible">',
                    '<rect width="1000" height="1000" fill="white"/>',
                    '<foreignObject y="-10" width="1000" height="1000"><span>', _prompt ,'</span></foreignObject></svg></svg>'
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return
            string(
                string.concat(
                    "data:application/json;base64,",
                    bytes(
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"', abi.encodePacked("#", _tokenId.toString()),'",','"description":"Prompter is a collection by You and Monas.",','"image":"data:image/svg+xml;base64,', buildImage(prompts[_tokenId]), '",','"attributes": [{"trait_type": "Timestamp", "value": "', promptTimestamp[_tokenId].toString() ,'"}, {"trait_type": "Length", "value": "', bytes(prompts[_tokenId]).length.toString() ,'"}]}'
                            )
                        )
                    )
                )
            );
    }

    function setSaleStatus(Status _status) public onlyOwner {
        saleStatus = _status;
    }

    function setMerkleRoot(bytes32 _rootWL, bytes32 _rootPrivate) public onlyOwner {
        _merkleRootWL = _rootWL;
        _merkleRootPrivate = _rootPrivate;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
