import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Minimal Proxy", function () {
  async function deployMinimalProxyFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, otherAccount2] = await ethers.getSigners();

    const PreservationAttacker = await ethers.getContractFactory(
      "PreservationAttacker"
    );
    const preservationAttacker = await PreservationAttacker.deploy();
    const preservationAttackerAddress = await preservationAttacker.getAddress();

    const Preservation = await ethers.getContractFactory("Preservation");
    const preservation = await Preservation.deploy(
      preservationAttackerAddress,
      preservationAttackerAddress
    );

    return { preservation, owner, otherAccount, otherAccount2 };
  }

  describe("Deployment", function () {
    it("Should set new Preservation owner contract", async function () {
      const { preservation, owner, otherAccount, otherAccount2 } =
        await loadFixture(deployMinimalProxyFixture);

      expect(await preservation.owner()).to.be.equal(owner.address);

      await preservation.setFirstTime(otherAccount.address);
      expect(await preservation.owner()).to.be.equal(otherAccount.address);

      await preservation.setFirstTime(otherAccount2.address);
      expect(await preservation.owner()).to.be.equal(otherAccount2.address);
    });
  });
});
