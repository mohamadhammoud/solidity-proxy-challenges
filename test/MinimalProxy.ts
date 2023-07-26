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
    const [owner, otherAccount] = await ethers.getSigners();

    const StoreMinimal = await ethers.getContractFactory("StoreMinimal");
    const storeMinimal = await StoreMinimal.deploy();
    const storeMinimalAddress = await storeMinimal.getAddress();

    const MinimalProxyFactory = await ethers.getContractFactory(
      "MinimalProxyFactory"
    );
    const minimalProxyFactory = await MinimalProxyFactory.deploy(
      storeMinimalAddress
    );

    return { minimalProxyFactory, StoreMinimal, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set new Minimal Proxy contract", async function () {
      const { minimalProxyFactory, StoreMinimal, owner } = await loadFixture(
        deployMinimalProxyFixture
      );

      const tx = await minimalProxyFactory.clone();

      // Wait for the transaction to be mined and get the receipt
      const receipt = await tx.wait();
      const proxy = receipt?.logs[0]?.args[0];
      await StoreMinimal.attach(proxy).setValue(1);
      expect(await StoreMinimal.attach(proxy).getValue()).to.equal(1);

      const owner1 = await StoreMinimal.attach(proxy).getOwner();

      expect(owner1).to.equal(owner.address);
    });
  });
});
