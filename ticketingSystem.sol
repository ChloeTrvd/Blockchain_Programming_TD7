pragma solidity ^0.5.0;

contract ticketingSystem {

uint nextArtistId = 1;

struct Artist{
    bytes32 name;
    int artistCategory;
    uint totalTicketSold;
    address payable owner;
}

mapping (uint => Artist) public artistsRegister;
mapping (address => uint) public ArtistToIndex;

function createArtist(bytes32 _name, int _category) public {

    artistsRegister[nextArtistId].name = _name;
    artistsRegister[nextArtistId].artistCategory = _category;
    artistsRegister[nextArtistId].totalTicketSold = 0;
    artistsRegister[nextArtistId].owner = msg.sender;
    ArtistToIndex[msg.sender] = nextArtistId;

    nextArtistId = nextArtistId + 1;
}

function modifyArtist(uint _artistId, bytes32 _name, int _category, address payable _newOwner) public {

    address owner = msg.sender;

    require(owner == artistsRegister[_artistId].owner);

    artistsRegister[_artistId].name = _name;
    artistsRegister[_artistId].artistCategory = _category;
    artistsRegister[_artistId].owner = _newOwner;
}


uint nextVenueId = 1;

struct Venue{
    bytes32 name;
    uint capacity;
    uint standardComission;
    address payable owner;
}

mapping (uint => Venue) public venuesRegister;

function createVenue(bytes32 _name, uint _capacity, uint _comission ) public {

    venuesRegister[nextVenueId].name = _name;
    venuesRegister[nextVenueId].capacity = _capacity;
    venuesRegister[nextVenueId].standardComission = _comission;
    venuesRegister[nextVenueId].owner = msg.sender;

    nextVenueId = nextVenueId + 1;
}

function modifyVenue(uint _venueId, bytes32 _name, uint _capacity, uint _comission, address payable _newOwner) public {
    
    require(msg.sender == venuesRegister[_venueId].owner);

    venuesRegister[_venueId].name = _name;
    venuesRegister[_venueId].capacity = _capacity;
    venuesRegister[_venueId].standardComission = _comission;
    venuesRegister[_venueId].owner = _newOwner;

}


// CREATING A CONCERT

uint nextConcertId = 1;

struct Concert{
    address owner;

    uint venueId;
    uint artistId;
    uint concertDate;
    uint ticketPrice;
    bool validatedByArtist;
    bool validatedByVenue;

    uint totalSoldTicket;
    uint totalMoneyCollected;
}

mapping (uint => Concert) public concertsRegister;

function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice)
  public
  returns (uint concertNumber)
  {
    require(_concertDate >= now);
    require(artistsRegister[_artistId].owner != address(0));
    require(venuesRegister[_venueId].owner != address(0));
    
    concertsRegister[nextConcertId].owner = msg.sender;
    concertsRegister[nextConcertId].concertDate = _concertDate;
    concertsRegister[nextConcertId].artistId = _artistId;
    concertsRegister[nextConcertId].venueId = _venueId;
    concertsRegister[nextConcertId].ticketPrice = _ticketPrice;

    concertsRegister[nextConcertId].totalSoldTicket = 0;
    concertsRegister[nextConcertId].totalMoneyCollected = 0;


    validateConcert(nextConcertId);
    concertNumber = nextConcertId;
    nextConcertId +=1;
  }


function validateConcert(uint _concertId) public
    {
        require(concertsRegister[_concertId].concertDate >= now);

        if (venuesRegister[concertsRegister[_concertId].venueId].owner == msg.sender){
            concertsRegister[_concertId].validatedByVenue = true;
        }

        if (artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender){
            concertsRegister[_concertId].validatedByArtist = true;
        }
    }




// EMITTING TICKETS

uint nextTicketId = 1;

struct Ticket{
    uint concertId;
    uint amountPaid;
    bool isAvailableForSale;
    address owner;
    bool isAvailable;

    // FOR 06_TicketSelling.js
    uint salePrice;
}

mapping (uint => Ticket) public ticketsRegister;


function createTicket(uint _concertId, address _ticketOwner) public {
    
    ticketsRegister[nextTicketId].concertId = _concertId;
    ticketsRegister[nextTicketId].owner = _ticketOwner;
    ticketsRegister[nextTicketId].amountPaid = concertsRegister[_concertId].ticketPrice;
    ticketsRegister[nextTicketId].isAvailable = true;
    ticketsRegister[nextTicketId].isAvailableForSale = false;

    nextTicketId += 1;
}

function emitTicket(uint _concertId, address _ticketOwner) public {
    
    require(concertsRegister[_concertId].artistId == ArtistToIndex[msg.sender]);
    
    createTicket(_concertId, _ticketOwner);

    concertsRegister[_concertId].totalSoldTicket += 1;
}


// USING TICKETS 
function useTicket(uint _ticketId) public
{
    require(msg.sender==ticketsRegister[_ticketId].owner);
    require(concertsRegister[ticketsRegister[_ticketId].concertId].concertDate <= now+ 1 days );
    require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue);
    ticketsRegister[_ticketId].isAvailable=false;
    ticketsRegister[_ticketId].isAvailableForSale=false;
    ticketsRegister[_ticketId].owner=address(0x0000);
}  
 


// BUYING TICKETS
function buyTicket(uint _concertId) public payable {

    createTicket(_concertId, msg.sender);

    concertsRegister[_concertId].totalSoldTicket++;
    concertsRegister[_concertId].totalMoneyCollected+=concertsRegister[_concertId].ticketPrice;
}


// TRANSFERRING TICKETS
function transferTicket(uint _ticketId, address _newOwner) public {
    require(msg.sender == ticketsRegister[_ticketId].owner);
    ticketsRegister[_ticketId].owner = _newOwner;
}


// CASHING OUT CONCERT
function cashOutConcert(uint _concertId, address payable _cashOutAddress) public {
    
    require(now>=concertsRegister[_concertId].concertDate );
    require(msg.sender == _cashOutAddress);
    
    artistsRegister[concertsRegister[_concertId].artistId].totalTicketSold += concertsRegister[_concertId].totalSoldTicket;
    concertsRegister[_concertId].totalMoneyCollected -= concertsRegister[_concertId].totalMoneyCollected;
}



// PUTTING UP TICKETS TO SELL
function offerTicketForSale(uint _ticketId, uint _salePrice) public {
    
    require(ticketsRegister[_ticketId].owner == msg.sender);
    require(ticketsRegister[_ticketId].amountPaid >= _salePrice);

    ticketsRegister[_ticketId].isAvailableForSale = true;
    ticketsRegister[_ticketId].salePrice = _salePrice;
}


// BUYING AUCTIONED TICKETS
function buySecondHandTicket(uint _ticketId) payable public {

    require(ticketsRegister[_ticketId].salePrice == msg.value);
    require(ticketsRegister[_ticketId].isAvailableForSale);

    ticketsRegister[_ticketId].owner = msg.sender;
    ticketsRegister[_ticketId].isAvailableForSale = false;
}

}