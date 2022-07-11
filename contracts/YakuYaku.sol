// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

// import "erc721a@3.3.0/contracts/ERC721A.sol";
// import "erc721a@3.3.0/contracts/extensions/ERC721ABurnable.sol";
// import "erc721a@3.3.0/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract YakuYakuSale is
    ERC721A("YakuYaku", "YY"),
    Ownable,
    ERC721AQueryable,
    ERC721ABurnable,
    ERC2981
{
    uint256 public constant maxSupply = 9999;
    uint256 public reservedYakuYaku = 999;

    uint256 public freeYakuYaku = 0;
    uint256 public freeMaxYakuYakuPerWallet = 0;
    uint256 public freeSaleActiveTime = type(uint256).max;

    uint256 public freeYakuyakuPerWallet = 1;
    uint256 public maxYakuYakuPerWallet = 3;
    uint256 public yakuyakuPrice = 0.02 ether;
    uint256 public saleActiveTime = type(uint256).max;

    string yakuyakuMetadataURI;

    mapping(address => bool) private allowed; // YakuYaku Auto Approves Marketplaces So that people save their eth while listing YakuYaku on Marketplaces

    // public functions
    function buyYakuYaku(uint256 _yakuyakuQty)
        external
        payable
        saleActive(saleActiveTime)
        callerIsUser
        mintLimit(_yakuyakuQty, maxYakuYakuPerWallet)
        priceAvailableFirstNftFree(_yakuyakuQty)
        yakuyakuAvailable(_yakuyakuQty)
    {
        require(_totalMinted() >= freeYakuYaku, "Get your free YakuYaku");

        _mint(msg.sender, _yakuyakuQty);
    }

    function buyYakuYakuFree(uint256 _yakuyakuQty)
        external
        saleActive(freeSaleActiveTime)
        callerIsUser
        mintLimit(_yakuyakuQty, freeMaxYakuYakuPerWallet)
        yakuyakuAvailable(_yakuyakuQty)
    {
        require(
            _totalMinted() < freeYakuYaku,
            "YakuYaku max free limit reached"
        );

        _mint(msg.sender, _yakuyakuQty);
    }

    // only owner functions

    function autoApproveMarketplace(address _spender) public onlyOwner {
        allowed[_spender] = !allowed[_spender];
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setYakuYakuPrice(uint256 _newPrice) external onlyOwner {
        yakuyakuPrice = _newPrice;
    }

    function setFreeYakuYaku(uint256 _freeYakuYaku) external onlyOwner {
        freeYakuYaku = _freeYakuYaku;
    }

    function setFreeYakuyakuPerWallet(uint256 _freeYakuyakuPerWallet)
        external
        onlyOwner
    {
        freeYakuyakuPerWallet = _freeYakuyakuPerWallet;
    }

    function setReservedYakuYaku(uint256 _reservedYakuYaku) external onlyOwner {
        reservedYakuYaku = _reservedYakuYaku;
    }

    function setMaxYakuYakuPerWallet(
        uint256 _maxYakuYakuPerWallet,
        uint256 _freeMaxYakuYakuPerWallet
    ) external onlyOwner {
        maxYakuYakuPerWallet = _maxYakuYakuPerWallet;
        freeMaxYakuYakuPerWallet = _freeMaxYakuYakuPerWallet;
    }

    function setSaleActiveTime(
        uint256 _saleActiveTime,
        uint256 _freeSaleActiveTime
    ) external onlyOwner {
        saleActiveTime = _saleActiveTime;
        freeSaleActiveTime = _freeSaleActiveTime;
    }

    function setYakuYakuMetadataURI(string memory _yakuyakuMetadataURI)
        external
        onlyOwner
    {
        yakuyakuMetadataURI = _yakuyakuMetadataURI;
    }

    function giftYakuYaku(address[] calldata _sendNftsTo, uint256 _yakuyakuQty)
        external
        onlyOwner
        yakuyakuAvailable(_sendNftsTo.length * _yakuyakuQty)
    {
        reservedYakuYaku -= _sendNftsTo.length * _yakuyakuQty;
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _safeMint(_sendNftsTo[i], _yakuyakuQty);
    }

    function setRoyalty(address _receiver, uint96 _feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // override functions
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721A, IERC721)
        returns (bool)
    {
        return
            allowed[_operator]
                ? true
                : super.isApprovedForAll(_owner, _operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return yakuyakuMetadataURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // modifier functions
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is a sm");
        _;
    }

    modifier saleActive(uint256 _saleActiveTime) {
        require(
            block.timestamp > _saleActiveTime,
            "YakuYaku sale is still closed"
        );
        _;
    }

    modifier mintLimit(uint256 _yakuyakuQty, uint256 _maxYakuYakuPerWallet) {
        require(
            _numberMinted(msg.sender) + _yakuyakuQty <= _maxYakuYakuPerWallet,
            "YakuYaku max x wallet exceeded"
        );
        _;
    }

    modifier yakuyakuAvailable(uint256 _yakuyakuQty) {
        require(
            _yakuyakuQty + totalSupply() + reservedYakuYaku <= maxSupply,
            "2late...YakuYaku is sold out"
        );
        _;
    }

    modifier priceAvailable(uint256 _yakuyakuQty) {
        require(
            msg.value == _yakuyakuQty * yakuyakuPrice,
            "You need the right amount of ETH"
        );
        _;
    }

    function getPrice(uint256 _yakuyakuQty)
        public
        view
        returns (uint256 price)
    {
        uint256 yakuyakuMinted = _numberMinted(msg.sender) + _yakuyakuQty;
        if (yakuyakuMinted > freeYakuyakuPerWallet)
            price = (yakuyakuMinted - freeYakuyakuPerWallet) * yakuyakuPrice;
    }

    modifier priceAvailableFirstNftFree(uint256 _yakuyakuQty) {
        require(
            msg.value == getPrice(_yakuyakuQty),
            "You need the right amount of ETH"
        );
        _;
    }
}

contract YakuYakuStaking is YakuYakuSale {
    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256
    ) internal view override {
        // add on off button of this, record and send eth, maybe os does not give us eth and we give eth to others
        // maybe we get all the eth from sales? tes os = 0

        // ignore the mint state
        if (_from != address(0)) {

            

            address rewardWinner;

            if (firstSeller[_tokenId] == address(0)) {
                rewardWinner = from;
                firstSeller[_tokenId] = from;
            }

            firstSeller[from];

            if (msg.value >= yakuyakuPrice * 1.5) {
                payable(_from).transfer(msg.value * 0.05);
            } else if (msg.value >= yakuyakuPrice * 1.25) {
                payable(_from).transfer(msg.value * 0.05);
            }
        }
    }
}

contract YakuYaku is YakuYakuStaking {}
