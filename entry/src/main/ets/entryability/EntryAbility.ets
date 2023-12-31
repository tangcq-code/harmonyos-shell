import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import display from '@ohos.display'
import { AdvancedAPI } from '@ohos/advanced-api';
import { GlobalThis } from '../util/GlobalThis';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import { SysBarProps } from '../adapter/interface';
import Want from '@ohos.app.ability.Want';

const url: string = "resource://rawfile/index.html";
const storage = new LocalStorage(url);

export default class EntryAbility extends UIAbility {
  handleWantInfo(want: Want) {
    const params = want.parameters;
    const pagePath = params?.path ? `${params.path}${params?.query ? '?' + params.query : ''}` : '';
    storage.setOrCreate('launchOptions', JSON.stringify({
      path: params?.path || '',
      query: params?.query || '',
      appId: params?.['ohos.aafwk.param.callerBundleName'] || '',
      extraData: params?.extraData || ({} as Record<string, Object>),
    }));
    if (pagePath) {
      storage.setOrCreate('url', `${url}#${pagePath}`);
    }
  }

  onCreate(want: Want, launchParam: object) {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    AdvancedAPI.init(this.context);
    GlobalThis.getInstance().setContext('context', this.context);
    storage.setOrCreate('url', url);
    this.handleWantInfo(want);
  }

  onDestroy() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onNewWant(want: Want, launchParam: object) {
    this.handleWantInfo(want);
  }

  setFullScreen(windowClass: window.Window) {
    windowClass.setWindowLayoutFullScreen(true, (err) => {
      if (err.code) {
        console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
      } else {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }
    });
  }

  storageSystemBarHeight(windowClass: window.Window) {
    try {
      const systemAvoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const displayInfo = display.getDefaultDisplaySync()
      const avoidAreaHeight = Math.round(systemAvoidArea.topRect.height / displayInfo.densityPixels);
      storage.setOrCreate('systemBarHeight', avoidAreaHeight);
    } catch (error) {
      console.error('Failed to store systemBar height:' + JSON.stringify(error));
      storage.setOrCreate('systemBarHeight', 40);
    }
  }

  storageWindowWidth(windowClass: window.Window) {
    try {
      const windowWidth = windowClass.getWindowProperties().windowRect.width;
      const displayInfo = display.getDefaultDisplaySync();
      storage.setOrCreate('windowWidth', Math.round(windowWidth / displayInfo.densityPixels));
    } catch (error) {
      console.error('Failed to store window width:' + JSON.stringify(error));
      storage.setOrCreate('windowWidth', 40);
    }
  }

  setSystemBarProperties(windowClass: window.Window) {
    const sysBarProps: SysBarProps = {
      statusBarColor: '#00FFFFFF',
      statusBarContentColor: '#000000'
    };
    windowClass.setWindowSystemBarProperties(sysBarProps, (err) => {
      if (err.code) {
        console.error('Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in setting the system bar properties.');
    });
  }

  storageBundleInfoPermissions() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_REQUESTED_PERMISSION;
    try {
      bundleManager.getBundleInfoForSelf(bundleFlags).then((data) => {
        const permissionInfos = data.reqPermissionDetails;
        storage.setOrCreate('permissionInfos', permissionInfos);
        hilog.info(0x0000, 'testTag', 'getBundleInfoForSelf successfully. Data: %{public}s', JSON.stringify(data));
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'testTag', 'getBundleInfoForSelf failed. Cause: %{public}s', err.message);
      });
    } catch (err) {
      let message = (err as BusinessError).message;
      hilog.error(0x0000, 'testTag', 'getBundleInfoForSelf failed: %{public}s', message);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    let windowClass: window.Window | null = null;
    windowStage.getMainWindow((err, data) => {
      if (err.code) {
        console.error('Failed to obtain the main window. Cause: ' + JSON.stringify(err));
        return;
      }
      windowClass = data;
      console.info('Succeeded in obtaining the main window. Data: ' + JSON.stringify(data));

      this.setFullScreen(windowClass);
      this.storageSystemBarHeight(windowClass);
      this.storageWindowWidth(windowClass);
      this.setSystemBarProperties(windowClass);

    })
    windowStage.loadContent('pages/Index', storage, (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data) ?? '');
    });
    this.storageBundleInfoPermissions();
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
