import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
const { ethers } = require("hardhat");

describe("Puzzle Wallet", function () {
  async function deployMinimalProxyFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, otherAccount2] = await ethers.getSigners();

    const PuzzleWallet = await ethers.deployContract("PuzzleWallet", []);
    const puzzleWalletAddress = await PuzzleWallet.getAddress();

    const PuzzleProxy = await ethers.deployContract(
      "PuzzleProxy",
      [
        owner.address,
        puzzleWalletAddress,
        ethers.hexlify(ethers.toUtf8Bytes("")), // 0x
      ],
      { value: ethers.parseEther("0.001") }
    );

    return { PuzzleProxy, owner, otherAccount, otherAccount2 };
  }

  describe("Deployment", function () {
    it("Should set new Proxy Wallet owner contract", async function () {
      const { PuzzleProxy, owner, otherAccount, otherAccount2 } =
        await loadFixture(deployMinimalProxyFixture);

      expect(await PuzzleProxy.admin()).to.be.equal(owner.address);

      const PuzzleProxyAttacker = await ethers.deployContract(
        "PuzzleProxyAttacker",
        [await PuzzleProxy.getAddress()],
        { value: ethers.parseEther("0.001") },
        otherAccount
      );

      expect(await PuzzleProxy.admin()).to.be.equal(
        await PuzzleProxyAttacker.getAddress()
      );
    });
  });
});
