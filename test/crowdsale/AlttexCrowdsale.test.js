import ether from '../helpers/ether';
import { advanceBlock } from '../helpers/advanceToBlock';
import { increaseTimeTo, duration } from '../helpers/increaseTime';
import latestTime from '../helpers/latestTime';
import EVMRevert from '../helpers/EVMRevert';

const BigNumber = web3.BigNumber;

const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(BigNumber))
    .should();

const AlttexCrowdsale = artifacts.require('AlttexCrowdsale');
const Alttex = artifacts.require('Alttex');

contract('AlttexCrowdsale', function ([_, owner, investor, wallet, purchaser]) {
    const rate = new BigNumber(1);
    const value = ether(42);
    const tokenSupply = 50000000*10**8;
    const expectedTokenAmount = rate.mul(value);
    let balance;
    const openingTime = 1520067600;

    before(async function () {
        // Advance to the next block to correctly read time in the solidity "now" function interpreted by testrpc
        await advanceBlock();
    });

    beforeEach(async function () {
        this.token = await Alttex.new({from: owner});
        this.crowdsale = await AlttexCrowdsale.new(rate, wallet, this.token.address);
        await this.token.transfer(this.crowdsale.address, tokenSupply,{from: owner});
    });

    describe('at start', function () {

        it('should have the correct balance', async function () {
            balance = await this.token.balanceOf(this.crowdsale.address);
            balance.should.be.bignumber.equal(tokenSupply);
        });

        it('accepting payments', async function () {
            await increaseTimeTo(openingTime);
            //await this.crowdsale.buyTokens(investor, { value, from: purchaser });
            //balance = await this.token.balanceOf(investor);
            //balance.should.be.bignumber.equal(value.mul(initialRate));
         });
    });
    

    
/*
    describe('accepting payments', function () {
        it('should accept payments', async function () {
            await this.crowdsale.send(value).should.be.fulfilled;
            await this.crowdsale.buyTokens(investor, { value: value, from: purchaser }).should.be.fulfilled;
        });
    });
    */
/*
    describe('high-level purchase', function () {
        it('should log purchase', async function () {
            const { logs } = await this.crowdsale.sendTransaction({ value: value, from: investor });
            const event = logs.find(e => e.event === 'TokenPurchase');
            should.exist(event);
            event.args.purchaser.should.equal(investor);
            event.args.beneficiary.should.equal(investor);
            event.args.value.should.be.bignumber.equal(value);
            event.args.amount.should.be.bignumber.equal(expectedTokenAmount);
        });

        it('should assign tokens to sender', async function () {
            await this.crowdsale.sendTransaction({ value: value, from: investor });
            let balance = await this.token.balanceOf(investor);
            balance.should.be.bignumber.equal(expectedTokenAmount);
        });

        it('should forward funds to wallet', async function () {
            const pre = web3.eth.getBalance(wallet);
            await this.crowdsale.sendTransaction({ value, from: investor });
            const post = web3.eth.getBalance(wallet);
            post.minus(pre).should.be.bignumber.equal(value);
        });
    });
    */
  /*

  describe('low-level purchase', function () {
    it('should log purchase', async function () {
      const { logs } = await this.crowdsale.buyTokens(investor, { value: value, from: purchaser });
      const event = logs.find(e => e.event === 'TokenPurchase');
      should.exist(event);
      event.args.purchaser.should.equal(purchaser);
      event.args.beneficiary.should.equal(investor);
      event.args.value.should.be.bignumber.equal(value);
      event.args.amount.should.be.bignumber.equal(expectedTokenAmount);
    });

    it('should assign tokens to beneficiary', async function () {
      await this.crowdsale.buyTokens(investor, { value, from: purchaser });
      const balance = await this.token.balanceOf(investor);
      balance.should.be.bignumber.equal(expectedTokenAmount);
    });

    it('should forward funds to wallet', async function () {
      const pre = web3.eth.getBalance(wallet);
      await this.crowdsale.buyTokens(investor, { value, from: purchaser });
      const post = web3.eth.getBalance(wallet);
      post.minus(pre).should.be.bignumber.equal(value);
    });
  });*/
});
