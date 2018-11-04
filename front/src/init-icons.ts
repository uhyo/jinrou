// Init Font Awesome icons.
import { library, dom, icon } from '@fortawesome/fontawesome-svg-core';
import {
  faQuestionCircle,
  faIdCard,
  faClock,
} from '@fortawesome/free-regular-svg-icons';
import {
  faPlusSquare,
  faMinusSquare,
  faSquare,
  faFolder,
  faFolderOpen,
  faSpinner,
  faLock,
  faUnlockAlt,
  faInfoCircle,
  faSearch,
  faTimes,
  faUser,
  faUserTimes,
  faUserSecret,
  faBan,
  faPen,
  faTrashAlt,
  faCheck,
  faSignal,
} from '@fortawesome/free-solid-svg-icons';

library.add(
  faQuestionCircle,
  faIdCard,
  faPlusSquare,
  faMinusSquare,
  faSquare,
  faFolder,
  faFolderOpen,
  faSpinner,
  faLock,
  faUnlockAlt,
  faInfoCircle,
  faTimes,
  faUser,
  faUserTimes,
  faUserSecret,
  faBan,
  faSearch,
  faPen,
  faTrashAlt,
  faCheck,
  faSignal,
  faClock,
);

// Publish to global.
(window as any).FontAwesome = {
  icon,
};

// currently this is needed.
dom.watch();
