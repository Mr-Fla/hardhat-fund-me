// SPDX-License-Identifier: MIT
//1. PRAGMA
pragma solidity ^0.8.8;

//2. IMPORTS
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//3. ERROR CODES
error FundMe__NotOwner(); // add contract__name

//4. INTERFACES, LIBRARIES,contracts--------------------------------------------------------------------

//5. CONTRACTS    "description"
/**  @title A contract for crowd funding
 *   @author Mr.Fla
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements s_priceFeed#s as our library
 */
contract FundMe {
    //5.1 TYPE DECLARATIONS
    using PriceConverter for uint256;

    //5.2 STATE VARIABLES !
    mapping(address => uint256) private s_addressToAmountFunded; // s => STORAGE VARIABLE
    address[] private s_funders;
    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    AggregatorV3Interface private s_priceFeed;

    //5.3 EVENTS

    //5.4 MODIFIER
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    //5.5 FUNCTIONS
    //constructor
    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    //receive
    //receive() external payable {
    //    fund();
    //}

    //fallback
    //fallback() external payable {
    //    fund();
    //}

    /**
     *   @notice This function funds this contract
     *   @dev This implements s_priceFeed#s as our library
     */
    //public
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    // very expensive
    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        //call vs delegatecall
        require(success, "Transfer failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        //mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // View / Pure
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
