// lib/HttpServer.ts
import express from "express";
import logger from "./Log2File";
import LnurlConfig from "../config/LnurlConfig";
import fs from "fs";
import { LnurlWithdraw } from "./LnurlWithdraw";
import { LnurlPay } from "./LnurlPay";
import {
  IResponseMessage,
  ErrorCodes,
} from "../types/jsonrpc/IResponseMessage";
import { IRequestMessage } from "../types/jsonrpc/IRequestMessage";
import { Utils } from "./Utils";
import IRespCreateLnurlWithdraw from "../types/IRespLnurlWithdraw";
import IReqCreateLnurlWithdraw from "../types/IReqCreateLnurlWithdraw";
import IReqLnurlWithdraw from "../types/IReqLnurlWithdraw";
import IRespLnServiceWithdrawRequest from "../types/IRespLnServiceWithdrawRequest";
import IRespCreateLnurlPay from "../types/IRespLnurlPay";
import IReqCreateLnurlPay from "../types/IReqCreateLnurlPay";
import IReqViewLnurlPay from "../types/IReqViewLnurlPay";
import IReqCreateLnurlPayRequest from "../types/IReqCreateLnurlPayRequest";
import IReqLnurlPayRequestCallback from "../types/IReqLnurlPayRequestCallback";
import IRespLnurlPay from "../types/IRespLnurlPay";
import IRespLnurlPayRequest from "../types/IRespLnurlPayRequest";
import IReqUpdateLnurlPay from "../types/IReqUpdateLnurlPay";
import IRespPayLnAddress from "../types/IRespPayLnAddress";
import { IReqPayLnAddress } from "../types/IReqPayLnAddress";

class HttpServer {
  // Create a new express application instance
  private readonly _httpServer: express.Application = express();
  private _lnurlConfig: LnurlConfig = JSON.parse(
    fs.readFileSync("data/config.json", "utf8")
  );
  private _lnurlWithdraw: LnurlWithdraw = new LnurlWithdraw(this._lnurlConfig);
  private _lnurlPay: LnurlPay = new LnurlPay(this._lnurlConfig);

  setup(): void {
    logger.debug("setup");
    this._httpServer.use(express.json());
  }

  async loadConfig(): Promise<void> {
    logger.debug("loadConfig");

    this._lnurlConfig = JSON.parse(fs.readFileSync("data/config.json", "utf8"));

    this._lnurlWithdraw.configureLnurl(this._lnurlConfig);
    this._lnurlPay.configureLnurl(this._lnurlConfig);
  }

  async createLnurlWithdraw(
    params: object | undefined
  ): Promise<IRespCreateLnurlWithdraw> {
    logger.debug("/createLnurlWithdraw params:", params);

    const reqCreateLnurlWithdraw: IReqCreateLnurlWithdraw = params as IReqCreateLnurlWithdraw;

    return await this._lnurlWithdraw.createLnurlWithdraw(
      reqCreateLnurlWithdraw
    );
  }

  async deleteLnurlWithdraw(
    params: object | undefined
  ): Promise<IRespCreateLnurlWithdraw> {
    logger.debug("/deleteLnurlWithdraw params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlWithdrawId = parseInt((params as any).lnurlWithdrawId);

    return await this._lnurlWithdraw.deleteLnurlWithdraw(lnurlWithdrawId);
  }

  async forceFallback(
    params: object | undefined
  ): Promise<IRespCreateLnurlWithdraw> {
    logger.debug("/forceFallback params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlWithdrawId = parseInt((params as any).lnurlWithdrawId);

    return await this._lnurlWithdraw.forceFallback(lnurlWithdrawId);
  }

  async getLnurlWithdraw(
    params: object | undefined
  ): Promise<IRespCreateLnurlWithdraw> {
    logger.debug("/getLnurlWithdraw params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlWithdrawId = parseInt((params as any).lnurlWithdrawId);

    return await this._lnurlWithdraw.getLnurlWithdraw(lnurlWithdrawId);
  }

  async createLnurlPay(
    params: object | undefined
  ): Promise<IRespCreateLnurlPay> {
    logger.debug("/createLnurlPay params:", params);

    const reqCreateLnurlPay: IReqCreateLnurlPay = params as IReqCreateLnurlPay;

    return await this._lnurlPay.createLnurlPay(reqCreateLnurlPay);
  }

  async updateLnurlPay(params: object | undefined): Promise<IRespLnurlPay> {
    logger.debug("/updateLnurlPay params:", params);

    const reqUpdateLnurlPay: IReqUpdateLnurlPay = params as IReqUpdateLnurlPay;

    return await this._lnurlPay.updateLnurlPay(reqUpdateLnurlPay);
  }

  async deleteLnurlPay(params: object | undefined): Promise<IRespLnurlPay> {
    logger.debug("/deleteLnurlPay params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlPayId = parseInt((params as any).lnurlPayId);

    return await this._lnurlPay.deleteLnurlPay(lnurlPayId);
  }

  async getLnurlPay(params: object | undefined): Promise<IRespCreateLnurlPay> {
    logger.debug("/getLnurlPay params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlPayId = parseInt((params as any).lnurlPayId);

    return await this._lnurlPay.getLnurlPay(lnurlPayId);
  }

  async deleteLnurlPayRequest(
    params: object | undefined
  ): Promise<IRespLnurlPayRequest> {
    logger.debug("/deleteLnurlPayRequest params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlPayRequestId = parseInt((params as any).lnurlPayRequestId);

    return await this._lnurlPay.deleteLnurlPayRequest(lnurlPayRequestId);
  }

  async getLnurlPayRequest(
    params: object | undefined
  ): Promise<IRespLnurlPayRequest> {
    logger.debug("/getLnurlPayRequest params:", params);

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const lnurlPayRequestId = parseInt((params as any).lnurlPayRequestId);

    return await this._lnurlPay.getLnurlPayRequest(lnurlPayRequestId);
  }

  async payLnAddress(params: object | undefined): Promise<IRespPayLnAddress> {
    logger.debug("/payLnAddress params:", params);

    const reqpayLnAddress: IReqPayLnAddress = params as IReqPayLnAddress;

    return await this._lnurlPay.payLnAddress(reqpayLnAddress);
  }

  async start(): Promise<void> {
    logger.info("Starting incredible service");

    this.setup();

    this._httpServer.post(this._lnurlConfig.URL_API_CTX, async (req, res) => {
      logger.debug(this._lnurlConfig.URL_API_CTX);

      const reqMessage: IRequestMessage = req.body;
      logger.debug("reqMessage.method:", reqMessage.method);
      logger.debug("reqMessage.params:", reqMessage.params);

      const response: IResponseMessage = {
        id: reqMessage.id,
      } as IResponseMessage;

      // Check the method and call the corresponding function
      switch (reqMessage.method) {
        case "createLnurlWithdraw": {
          const result: IRespCreateLnurlWithdraw = await this.createLnurlWithdraw(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "getLnurlWithdraw": {
          const result: IRespCreateLnurlWithdraw = await this.getLnurlWithdraw(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "deleteLnurlWithdraw": {
          const result: IRespCreateLnurlWithdraw = await this.deleteLnurlWithdraw(
            reqMessage.params || {}
          );

          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "createLnurlPay": {
          const result: IRespCreateLnurlPay = await this.createLnurlPay(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "updateLnurlPay": {
          const result: IRespLnurlPay = await this.updateLnurlPay(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "getLnurlPay": {
          const result: IRespLnurlPay = await this.getLnurlPay(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "deleteLnurlPay": {
          const result: IRespLnurlPay = await this.deleteLnurlPay(
            reqMessage.params || {}
          );

          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "getLnurlPayRequest": {
          const result: IRespLnurlPayRequest = await this.getLnurlPayRequest(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "deleteLnurlPayRequest": {
          const result: IRespLnurlPayRequest = await this.getLnurlPayRequest(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "payLnAddress": {
          const result: IRespPayLnAddress = await this.payLnAddress(
            reqMessage.params || {}
          );
          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "processCallbacks": {
          this._lnurlWithdraw.processCallbacks();

          response.result = {};
          break;
        }

        case "processFallbacks": {
          this._lnurlWithdraw.processFallbacks();

          response.result = {};
          break;
        }

        case "forceFallback": {
          const result: IRespCreateLnurlWithdraw = await this.forceFallback(
            reqMessage.params || {}
          );

          response.result = result.result;
          response.error = result.error;
          break;
        }

        case "encodeBech32": {
          response.result = await Utils.encodeBech32(
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            (reqMessage.params as any).s
          );
          break;
        }

        case "decodeBech32": {
          response.result = await Utils.decodeBech32(
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            (reqMessage.params as any).s
          );
          break;
        }

        case "reloadConfig":
          await this.loadConfig();

        // eslint-disable-next-line no-fallthrough
        case "getConfig":
          response.result = this._lnurlConfig;
          break;

        default:
          response.error = {
            code: ErrorCodes.MethodNotFound,
            message: "No such method!",
          };
          break;
      }

      if (response.error) {
        response.error.data = reqMessage.params as never;
        res.status(400).json(response);
      } else {
        res.status(200).json(response);
      }
    });

    // LN Service LNURL Withdraw Request
    this._httpServer.get(
      // this._lnurlConfig.LN_SERVICE_CTX + // Stripped by traefik
      this._lnurlConfig.LN_SERVICE_WITHDRAW_REQUEST_CTX,
      async (req, res) => {
        logger.info(
          this._lnurlConfig.LN_SERVICE_WITHDRAW_REQUEST_CTX + ":",
          req.query
        );

        const response: IRespLnServiceWithdrawRequest = await this._lnurlWithdraw.lnServiceWithdrawRequest(
          req.query.s as string
        );

        if (response.status) {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    // LN Service LNURL Withdraw
    this._httpServer.get(
      // this._lnurlConfig.LN_SERVICE_CTX + // Stripped by traefik
      this._lnurlConfig.LN_SERVICE_WITHDRAW_CTX,
      async (req, res) => {
        logger.info(this._lnurlConfig.LN_SERVICE_WITHDRAW_CTX + ":", req.query);

        const response = await this._lnurlWithdraw.lnServiceWithdraw({
          k1: req.query.k1,
          pr: req.query.pr,
          balanceNotify: req.query.balanceNotify,
        } as IReqLnurlWithdraw);

        if (response.status === "ERROR") {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    // LN Service LNURL Pay specs (step 3)
    this._httpServer.get(
      // this._lnurlConfig.LN_SERVICE_CTX + // Stripped by traefik
      this._lnurlConfig.LN_SERVICE_PAY_SPECS_CTX + "/:externalId",
      async (req, res) => {
        logger.info(
          this._lnurlConfig.LN_SERVICE_PAY_SPECS_CTX + ":",
          req.params
        );

        const response = await this._lnurlPay.lnServicePaySpecs({
          externalId: req.params.externalId,
        } as IReqViewLnurlPay);

        if (response.status === "ERROR") {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    // LN Service LNURL Pay specs (step 3) lightning address format
    this._httpServer.get(
      "/.well-known/lnurlp/:externalId",
      async (req, res) => {
        logger.info("/.well-known/lnurlp/:", req.params);

        const response = await this._lnurlPay.lnServicePaySpecs({
          externalId: req.params.externalId,
        } as IReqViewLnurlPay);

        if (response.status === "ERROR") {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    // LN Service LNURL Pay request (step 5)
    this._httpServer.get(
      // this._lnurlConfig.LN_SERVICE_CTX + // Stripped by traefik
      this._lnurlConfig.LN_SERVICE_PAY_REQUEST_CTX + "/:externalId",
      async (req, res) => {
        logger.info(
          this._lnurlConfig.LN_SERVICE_PAY_REQUEST_CTX + ":",
          req.params
        );

        const response = await this._lnurlPay.lnServicePayRequest({
          externalId: req.params.externalId,
          amount: req.query.amount,
        } as IReqCreateLnurlPayRequest);

        if (response.status === "ERROR") {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    // LN Service LNURL Pay request callback (called by CN when bolt11 paid)
    this._httpServer.post(
      // this._lnurlConfig.LN_SERVICE_CTX + // Stripped by traefik
      this._lnurlConfig.URL_CTX_PAY_WEBHOOKS + "/:label",
      async (req, res) => {
        logger.info(this._lnurlConfig.URL_CTX_PAY_WEBHOOKS + ":", req.params);

        const response = await this._lnurlPay.lnurlPayRequestCallback({
          bolt11Label: req.params.label,
        } as IReqLnurlPayRequestCallback);

        if (response.error) {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    this._httpServer.post(
      this._lnurlConfig.URL_CTX_WITHDRAW_WEBHOOKS,
      async (req, res) => {
        logger.info(
          this._lnurlConfig.URL_CTX_WITHDRAW_WEBHOOKS + ":",
          req.body
        );

        const response = await this._lnurlWithdraw.processBatchWebhook(
          req.body
        );

        if (response.error) {
          res.status(400).json(response);
        } else {
          res.status(200).json(response);
        }
      }
    );

    this._httpServer.listen(this._lnurlConfig.URL_API_PORT, () => {
      logger.info(
        "Express HTTP server listening on port:",
        this._lnurlConfig.URL_API_PORT
      );
    });
  }
}

export { HttpServer };
