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

contract Prompter is ERC721Enumerable, Ownable {
    using Strings for uint256;
    enum Status { Inactive, Private, Whitelist, Public }

    mapping (string => bool) public prompts;
    mapping (address => uint256) public promptCount;
    mapping (uint256 => string) private promptsWithIDs;
    mapping (address => uint256) public whitelistCount;
    mapping (address => uint256) public privateCount;
    
    uint256 public price = 0.0069 ether;
    uint256 public wlPrice = 0.0042 ether;

    uint256 public maxPerWallet = 5;
    uint256 public maxPerWalletWL = 2;
    uint256 public maxPerWalletPrivate = 3;

    uint256 public maxSupply = 10000;
    uint256 public privateSupply = 1260;
    uint256 public wlSupply = 1000;

    Status public saleStatus = Status.Inactive;
    
    constructor() ERC721("Prompter", "TPC") {}

    function mint(string memory _prompt) public payable {
        require(getStatus() == 3, "Public sale isn't active.");
        require(bytes(_prompt).length < 422, "Max length 421 // Only base64 characters");
        require(prompts[_prompt] == false, "This prompt claimed.");
        require(msg.value >= price, "Art isn't expensive.");
        require(promptCount[msg.sender] < maxPerWallet + 1, "You can mint up to 5 tokens.");
        require(totalSupply() < maxSupply + 1, "Sold out.");

        prompts[_prompt] = true;
        promptsWithIDs[totalSupply() + 1] = _prompt;
        promptCount[msg.sender] += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintWL(string memory _prompt) public payable {
        // check wallet for whitelist
        require(getStatus() == 2, "Whitelist sale isn't active.");
        require(bytes(_prompt).length < 422, "Max length 421 // Only base64 characters");
        require(prompts[_prompt] == false, "This prompt claimed.");
        require(msg.value >= wlPrice, "Art isn't expensive.");
        require(whitelistCount[msg.sender] < maxPerWalletWL + 1, "You can mint up to 2 tokens.");
        require(totalSupply() < wlSupply + 1, "WL ended.");

        prompts[_prompt] = true;
        promptsWithIDs[totalSupply() + 1] = _prompt;
        promptCount[msg.sender] += 1;
        whitelistCount[msg.sender] += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintPrivate(string memory _prompt) public {
        // check wallet for private
        require(getStatus() == 1, "Private sale isn't active.");
        require(bytes(_prompt).length < 422, "Max length 421 // Only base64 characters");
        require(prompts[_prompt] == false, "This prompt claimed.");
        require(privateCount[msg.sender] < maxPerWalletPrivate + 1, "You can mint up to 3 tokens.");
        require(totalSupply() < privateSupply + 1, "Private sale ended.");

        prompts[_prompt] = true;
        promptsWithIDs[totalSupply() + 1] = _prompt;
        promptCount[msg.sender] += 1;
        privateCount[msg.sender] += 1;

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function buildImage(string memory _Prompt) internal pure returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    '<rect height="100%" width="100%" y="0" x="0" fill="#0c0c0c"/>',
                    '<defs>',
                    '<path id="path1" d="M7.55,33.94H484M7.55,67.38H484M7.3,100.83H483.74M7.44,134.24H483.88M7.44,167.67H483.88M7.44,201.11H483.88M7.18,234.54H483.62M7.74,267.97H484.19M7.74,301.41H484.19M7.49,334.86H483.92M7.63,368.27H484.07M7.63,401.7H484.07M7.63,435.14H484.07M7.37,468.57H483.8"></path>',
                    '</defs>',
                    '<use xlink:href="#path1" />',
                    '<text font-size="26.47px" fill="whitesmoke" font-family="Courier New">',
                    '<textPath xlink:href="#path1">', _Prompt,'</textPath></text>',
                    '</svg>'
                )
            );
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(
                    string.concat(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked('{"name":"', abi.encodePacked("#", _tokenId.toString()),'",', '"description":"Prompter is a collection by You and Monas."', '"image":"data:image/svg+xml;base64', buildImage(promptsWithIDs[_tokenId]), '"}')
                        )
                    )
                );
    }

    function getPrice() public view returns (uint256) {
        return price;
    }
    
    function getStatus() public view returns (uint256) {
        return uint256(saleStatus);
    }

    function setSaleStatus(Status _status) public onlyOwner {
        saleStatus = _status;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
