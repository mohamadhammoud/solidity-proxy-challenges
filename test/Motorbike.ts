import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
const { ethers, upgrades } = require("hardhat");

describe("Motorbike Challenge", function () {
  async function deployMinimalProxyFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, otherAccount2] = await ethers.getSigners();

    const Engine = await ethers.deployContract("Engine", []);
    const engineAddress = await Engine.getAddress();

    const Motorbike = await ethers.deployContract("Motorbike", [engineAddress]);

    return { Motorbike, Engine, owner, otherAccount, otherAccount2 };
  }

  describe("Deployment", function () {
    it("Should Destroy Engine contract", async function () {
      const { Motorbike, Engine, owner, otherAccount, otherAccount2 } =
        await loadFixture(deployMinimalProxyFixture);

      const engineAddress = await Engine.getAddress();

      let motorbikeAttacker = await ethers.deployContract("MotorbikeAttacker", [
        engineAddress,
      ]);

      await motorbikeAttacker.attack();
      await motorbikeAttacker.check();
    });
  });
});
