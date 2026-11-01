import MockGameServer from '../mocks/mock_gameserver.js';
import RealGameServer from './realgameserver.js';
import Constants from '../game/const.js';

/**
 * Conditional game Server
 * For debugging, exports mock game server, for production, uses realgameserver service
 */

const ExportedServer = Constants.useMockServer ? MockGameServer : RealGameServer;
export default ExportedServer;