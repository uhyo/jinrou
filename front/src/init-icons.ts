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
  faUnlock,
  faInfoCircle,
  faSearch,
  faTimes,
  faUser,
  faUserTimes,
  faUserTie,
  faUserSecret,
  faBan,
  faPen,
  faTrashAlt,
  faCheck,
  faSignal,
  faCaretSquareUp,
  faCaretSquareDown,
  faBars,
  faMicrophoneSlash,
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
  faUnlock,
  faInfoCircle,
  faTimes,
  faUser,
  faUserTimes,
  faUserTie,
  faUserSecret,
  faBan,
  faSearch,
  faPen,
  faTrashAlt,
  faCheck,
  faSignal,
  faClock,
  faCaretSquareUp,
  faCaretSquareDown,
  faBars,
  faMicrophoneSlash,
);

// Publish to global.
(window as any).FontAwesome = {
  icon,
};

// currently this is needed.
dom.watch();
