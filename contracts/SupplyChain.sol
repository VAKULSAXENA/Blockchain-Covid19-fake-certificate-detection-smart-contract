// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library CryptoSuite{

    function splitSignature(bytes memory sig) internal pure returns(uint8 v,bytes32 r,bytes32 s){
        require(sig.length==65);

        assembly {
            r:=mload(add(sig,32))
            s:=mload(add(sig,64))
            v:=byte(0,mload(add(sig,96)))

        }
        return (v,r,s);
    }

    function recoverSigner(bytes32 message,bytes memory sig) internal pure returns (address) {
        (uint8 v,bytes32 r,bytes32 s)=splitSignature(sig);
        return ecrecover(message,v,r,s);
    }
}

contract Supplychain {

    enum Status {MANUFACTURED,DELIVERING_INTERNATIONAL,STORED,DELIVERING_LOCAL,DELIVERED}

    struct Certificate {
        uint id;
        Entity issuer;
        Entity prover;
        bytes signature;
        Status status;
    }

    enum Mode {ISSUER,PROVER,VERIFIER}

    struct Entity {
        address id;
        Mode mode;
        uint[] certificateIds;
    }

    struct VaccineBatch{
        uint id;
        string brand;
        address manufacturer;
        uint[] certificateIds;
    }

    uint public constant MAX_CERTIFICATIONS = 2;

    uint[] public certificateIds;
    uint[] public vaccineBatchIds;

    mapping(uint=>VaccineBatch) public vaccineBatches;
    mapping(uint=>Certificate) public certificates;
    mapping(address=>Entity) public entities;

    function addEntity(address _id,string memory _mode) public {
        Mode mode = convertStringtoMode(_mode);
        uint[] memory _certificateIds= new uint[](MAX_CERTIFICATIONS);
        Entity memory entity=Entity(_id,mode,_certificateIds);
        entities[_id]=entity;
    }

    function convertStringtoMode(string memory _mode) private pure returns(Mode mode){
        bytes32 encodeMode=keccak256(abi.encodePacked(_mode));
        bytes32 encodeMode0=keccak256(abi.encodePacked("ISSUER"));
        bytes32 encodeMode1=keccak256(abi.encodePacked("PROVER"));
        bytes32 encodeMode2=keccak256(abi.encodePacked("VERIFIER"));

        if(encodeMode==encodeMode0){
            return Mode.ISSUER;
        }
        else if(encodeMode==encodeMode1){
            return Mode.PROVER;
        }
        else if(encodeMode==encodeMode0){
            return Mode.VERIFIER;
        }

        revert("received invalid entity mode");
        
        
    }
    function addVaccineBatch(string memory _brand,address manufacturer) public returns (uint) {
        uint[] memory _certificateIds= new uint[](MAX_CERTIFICATIONS);
        uint id=vaccineBatchIds.length;
        VaccineBatch memory batch=VaccineBatch(id,_brand,manufacturer,_certificateIds);
        vaccineBatches[id]=batch;
        vaccineBatchIds.push(id);
        return id;
        
    }

   function issueCertificate(
        address _issuer,address _prover,string memory _status,
        uint vaccineBatchId,bytes memory signature) public returns (uint){
        Entity memory issuer=entities[_issuer];
        require(issuer.mode==Mode.ISSUER);

        Entity memory prover=entities[_prover];
        require(prover.mode==Mode.PROVER);

        Status status = convertStringtoModeStatus(_status);

        uint id=certificateIds.length;
        Certificate memory certificate=Certificate(id,issuer,prover,signature,status);
        certificateIds.push(certificateIds.length);
        certificates[certificateIds.length-1]=certificate;

            return certificateIds.length-1;

   }
   

    function convertStringtoModeStatus(string memory _status) private pure returns(Status status){
        bytes32 encodeStatus=keccak256(abi.encodePacked(_status));
        bytes32 encodeStatus0=keccak256(abi.encodePacked("MANUFACTURED"));
        bytes32 encodeStatus1=keccak256(abi.encodePacked("DELIVERING_INTERNATIONAL"));
        bytes32 encodeStatus2=keccak256(abi.encodePacked("STORED")); 
        bytes32 encodeStatus3=keccak256(abi.encodePacked("DELIVERING_LOCAL")); 
        bytes32 encodeStatus4=keccak256(abi.encodePacked("DELIVERED")); 

        if(encodeStatus==encodeStatus0){
            return Status.MANUFACTURED;
        }
        else if(encodeStatus==encodeStatus1){
            return Status.DELIVERING_INTERNATIONAL;
        }
        else if(encodeStatus==encodeStatus2){
            return Status.STORED;
        }
        else if(encodeStatus==encodeStatus3){
            return Status.DELIVERING_LOCAL;
        }
        else if(encodeStatus==encodeStatus4){
            return Status.DELIVERED;
        }
       
     

        revert("received invalid Certificate Status");
        
        
    }
    
    function isMatchingSignature(bytes32 message,uint id,address issuer) public view returns (bool){
        Certificate memory cert = certificates[id];
        require(cert.issuer.id==issuer);

        address recoveredSigner=CryptoSuite.recoverSigner(message,cert.signature);

        return recoveredSigner==cert.issuer.id;
    }

}