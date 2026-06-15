import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseService } from '../service/DatabaseService';
import { AuthService } from '../service/AuthService';

const DOMAIN = 0x0000;

/**
 * 应用入口Ability
 * 负责初始化数据库和加载首页
 */
export default class EntryAbility extends UIAbility {
  private dbService: DatabaseService = DatabaseService.getInstance();
  private authService: AuthService = AuthService.getInstance();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 初始化数据库和认证服务
    this.dbService.initDatabase(this.context).then(() => {
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'Database initialized successfully');
      return this.authService.init(this.context);
    }).then(() => {
      hilog.info(DOMAIN, 'testTag', '%{public}s', 'AuthService initialized successfully');
    }).catch((error: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Init failed: %{public}s', error.message);
    });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 加载登录页（LoginPage 会检查登录状态，已登录则自动跳转首页）
    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}