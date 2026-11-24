/**
 * tests/sharedMatchController.test.js
 *
 * Unit tests for creator ownership and creator-only delete enforcement
 * in controllers/sharedMatchController.js.
 */

'use strict';

jest.mock('../models/SharedMatch', () => {
  const mockModel = {
    find: jest.fn(),
    findOne: jest.fn(),
    findOneAndUpdate: jest.fn(),
    deleteOne: jest.fn(),
    formatForClient: jest.fn((doc) => ({
      _id: doc.clientMatchId,
      creatorId: doc.creatorId ?? null,
      team1Name: doc.team1Name,
      team2Name: doc.team2Name,
      totalOvers: doc.totalOvers,
      syncVersion: doc.syncVersion ?? 1,
    })),
  };
  return mockModel;
});

const SharedMatch = require('../models/SharedMatch');
const ctrl = require('../controllers/sharedMatchController');

function createMockRes() {
  const res = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
  return res;
}

describe('sharedMatchController – creator ownership', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('upsertSharedMatch sets creatorId only on insert ($setOnInsert)', async () => {
    const req = {
      method: 'PUT',
      params: { id: 'match_123' },
      headers: { 'x-device-id': 'dev_creator_1' },
      body: {
        team1Name: 'Tigers',
        team2Name: 'Lions',
        totalOvers: 10,
      },
    };
    const res = createMockRes();
    const next = jest.fn();

    SharedMatch.findOneAndUpdate.mockResolvedValue({
      clientMatchId: 'match_123',
      creatorId: 'dev_creator_1',
      team1Name: 'Tigers',
      team2Name: 'Lions',
      totalOvers: 10,
      syncVersion: 1,
    });

    await ctrl.upsertSharedMatch(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(SharedMatch.findOneAndUpdate).toHaveBeenCalledTimes(1);
    const [, updateDoc] = SharedMatch.findOneAndUpdate.mock.calls[0];
    expect(updateDoc.$setOnInsert).toEqual({ creatorId: 'dev_creator_1' });
    expect(updateDoc.$set.creatorId).toBeUndefined();
    expect(res.statusCode).toBe(200);
    expect(res.body.match.creatorId).toBe('dev_creator_1');
  });

  test('deleteSharedMatch returns 404 when match does not exist', async () => {
    SharedMatch.findOne.mockReturnValue({ lean: jest.fn().mockResolvedValue(null) });

    const req = {
      params: { id: 'missing_match' },
      headers: { 'x-device-id': 'dev_creator_1' },
      query: {},
    };
    const res = createMockRes();
    const next = jest.fn();

    await ctrl.deleteSharedMatch(req, res, next);

    expect(res.statusCode).toBe(404);
    expect(next).toHaveBeenCalledWith(expect.any(Error));
    expect(SharedMatch.deleteOne).not.toHaveBeenCalled();
  });

  test('deleteSharedMatch returns 403 when requester is not the creator', async () => {
    SharedMatch.findOne.mockReturnValue({
      lean: jest.fn().mockResolvedValue({
        clientMatchId: 'match_123',
        creatorId: 'dev_creator_1',
      }),
    });

    const req = {
      params: { id: 'match_123' },
      headers: { 'x-device-id': 'dev_other_user' },
      query: {},
    };
    const res = createMockRes();
    const next = jest.fn();

    await ctrl.deleteSharedMatch(req, res, next);

    expect(res.statusCode).toBe(403);
    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'Only the match creator can delete this match' })
    );
    expect(SharedMatch.deleteOne).not.toHaveBeenCalled();
  });

  test('deleteSharedMatch returns 403 when match has no creatorId or requesterId is missing', async () => {
    SharedMatch.findOne.mockReturnValue({
      lean: jest.fn().mockResolvedValue({
        clientMatchId: 'legacy_match',
        creatorId: null,
      }),
    });

    const req = {
      params: { id: 'legacy_match' },
      headers: { 'x-device-id': 'dev_someone' },
      query: {},
    };
    const res = createMockRes();
    const next = jest.fn();

    await ctrl.deleteSharedMatch(req, res, next);

    expect(res.statusCode).toBe(403);
    expect(SharedMatch.deleteOne).not.toHaveBeenCalled();
  });

  test('deleteSharedMatch deletes match when requesterId matches creatorId', async () => {
    SharedMatch.findOne.mockReturnValue({
      lean: jest.fn().mockResolvedValue({
        clientMatchId: 'match_123',
        creatorId: 'dev_creator_1',
      }),
    });
    SharedMatch.deleteOne.mockResolvedValue({ deletedCount: 1 });

    const req = {
      params: { id: 'match_123' },
      headers: { 'x-device-id': 'dev_creator_1' },
      query: {},
    };
    const res = createMockRes();
    const next = jest.fn();

    await ctrl.deleteSharedMatch(req, res, next);

    expect(next).not.toHaveBeenCalled();
    expect(SharedMatch.deleteOne).toHaveBeenCalledWith({ clientMatchId: 'match_123' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
