package cn.fly.verify.flutter;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;
import androidx.annotation.NonNull;
import cn.fly.verify.OAuthPageEventCallback;
import cn.fly.verify.OperationCallback;
import cn.fly.verify.FlyVerify;
import cn.fly.verify.VerifyCallback;
import cn.fly.verify.common.exception.VerifyException;
import cn.fly.verify.datatype.LandUiSettings;
import cn.fly.verify.datatype.UiSettings;
import cn.fly.verify.datatype.VerifyResult;
import cn.fly.verify.ui.component.CommonProgressDialog;
import cn.fly.verify.flutter.impl.LandUiSettingsTransfer;
import cn.fly.verify.flutter.impl.UiSettingsTransfer;
import cn.fly.verify.CustomViewClickListener;
import android.view.View;
import java.util.HashMap;
import java.util.Map;
import java.lang.IllegalStateException;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;


public class FlyverifyPlugin implements FlutterPlugin,MethodCallHandler, EventChannel.StreamHandler {
	private static final String TAG = "FlyverifyPlugin";
	//桥接channel，需要和flutter一致
	public static final String METHOD_CHANNEL = "com.fly.flyverify.methodChannel";
	public static final String EVENT_CHANNEL = "com.fly.flyverify.verifyEventChannel";

	private MethodChannel methodChannel;
	private EventChannel eventChannel;
	private EventChannel.EventSink eventSink;

	public FlyverifyPlugin(){
		setChannel();
	}

	/**
	 * 设置跨平台插件渠道
	 */
	private void setChannel() {
		new Thread(new Runnable() {
			@Override
			public void run() {
				FlyVerify.setChannel(4);
			}
		}).start();
	}

	/**
	 * Flutter调用接口
	 * @param call 方法名及参数
	 * @param result 用于接口回调
	 */
	@Override
	public void onMethodCall(MethodCall call, Result result) {
		switch (call.method) {
			case "preVerify":
				//预取号
				preVerify(call, result);
				break;
			case "verify":
				//取号
				verify(call, result);
				break;
			case "setAndroidPortraitLayout":
				//竖屏
				setPortraitUiSettings(call, result);
				break;
			case "setAndroidLandscapeLayout":
				//横屏
				setLandUiSettings(call, result);
				break;
			case "finishOAuthPage":
				//关闭授权页面
				finshOauthPage();
				break;
			case "autoFinishOAuthPage":
				//是否自动关闭授权页面
				autoFinishOauthPage(call);
				otherLoginAutoFinishOAuthPage(call, result);
				break;
			case "OtherOAuthPageCallBack":
				//授权页面其他回调
				otherOAuthPageCallBack(call, result);
				break;
			case "setTimeOut":
				//超时设置
				setTimeOut(call, result);
				break;
			case "enableDebug":
				//是否输出运营商日志
				setDebugMode(call, result);
				break;
			case "getVersion":
				//版本号
				getVersion(result);
				break;
			case "secVerifyEnable":
				//本地环境是否支持
				isVerifySupport(result);
				break;
			case "uploadPrivacyStatus":
				//提交隐私协议结果
				submitPrivacyGrantResult(call, result);
				break;
			case "hideLoading":
				CommonProgressDialog.dismissProgressDialog();
				break;
			case "toast":
				toast(call, result);
				break;
			case "register":

				break;
			default:
				break;
		}
	}

	private void init(MethodCall call, Result result) {
		if (call.hasArgument("appKey") && call.hasArgument("appSecret")) {
			String appKey = call.argument("appKey");
			String appSecret = call.argument("appSecret");
			FlyVerify.init(FlyVerify.getContext(), appKey, appSecret);
		}
	}

	private void submitPrivacyGrantResult(MethodCall call, Result result) {
		if (call.hasArgument("status")) {
			Boolean grantResult = call.argument("status");
			FlyVerify.submitPolicyGrantResult(grantResult);
		}
	}

	private void isVerifySupport(Result result) {
		Boolean isSupport = FlyVerify.isVerifySupport();
		try {
			result.success(isSupport);
		}catch (IllegalStateException e) {

		}
	}

	private void setPortraitUiSettings(MethodCall call, Result result) {

		if (call.hasArgument("androidPortraitConfig")) {
			HashMap map = call.argument("androidPortraitConfig");
			UiSettings uiSettings = UiSettingsTransfer.transferUiSettings(map, new CustomViewClickListener(){
				@Override
				public void onClick(View view) {
					final Map<String, Object> map = new HashMap<String, Object>();
					map.put("customViewClick", view.getTag());
					new Handler(Looper.getMainLooper()).post(new Runnable() {
						@Override
						public void run() {
							try {
								eventSink.success(map);
							}catch (IllegalStateException e) {

							}
						}
					});
				}
			});
			FlyVerify.setUiSettings(uiSettings);
		}
	}
	private void setLandUiSettings(MethodCall call, Result result) {
		if (call.hasArgument("androidLandscapeConfig")) {
			HashMap map = call.argument("androidLandscapeConfig");
			LandUiSettings uiSettings = LandUiSettingsTransfer.transferLandUiSettings(map, new CustomViewClickListener(){
				@Override
				public void onClick(View view) {
					final Map<String, Object> map = new HashMap<String, Object>();
					map.put("customViewClick", view.getTag());
					new Handler(Looper.getMainLooper()).post(new Runnable() {
						@Override
						public void run() {
							try {
								eventSink.success(map);
							}catch (IllegalStateException e) {

							}
						}
					});
				}
			});
			FlyVerify.setLandUiSettings(uiSettings);
		}
	}

	private void finshOauthPage() {
		FlyVerify.finishOAuthPage();
	}

	private void autoFinishOauthPage(MethodCall call) {
		boolean hasArg = call.hasArgument("autoFinish");
		if (hasArg) {
			Boolean autoFinish = call.argument("autoFinish");
			FlyVerify.autoFinishOAuthPage(autoFinish);
		}
	}

	private void otherLoginAutoFinishOAuthPage(MethodCall call, Result result) {
		if (call.hasArgument("autoFinish")) {
			Boolean autoFinish = call.argument("autoFinish");
			FlyVerify.otherLoginAutoFinishOAuthPage(autoFinish);
		}
	}


	private void otherOAuthPageCallBack(MethodCall call, final Result result) {
		FlyVerify.OtherOAuthPageCallBack(new OAuthPageEventCallback() {
			@Override
			public void initCallback(OAuthPageEventResultCallback cb) {
				cb.pageOpenCallback(new PageOpenedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "pageOpenCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.loginBtnClickedCallback(new LoginBtnClickedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "loginBtnClickedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.agreementPageClosedCallback(new AgreementPageClosedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "agreementPageClosedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.agreementPageOpenedCallback(new AgreementClickedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "agreementPageOpenedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								//将封装好的数据通过result传会给flutter
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.cusAgreement1ClickedCallback(new CusAgreement1ClickedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "cusAgreement1ClickedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.cusAgreement2ClickedCallback(new CusAgreement2ClickedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "cusAgreement2ClickedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.cusAgreement3ClickedCallback(new CusAgreement3ClickedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "cusAgreement3ClickedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.checkboxStatusChangedCallback(new CheckboxStatusChangedCallback() {
					@Override
					public void handle(boolean b) {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "checkboxStatusChangedCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
				cb.pageCloseCallback(new PageClosedCallback() {
					@Override
					public void handle() {
						final Map<String, Object> map = new HashMap<String, Object>();
						map.put("ret", "pageCloseCallback");
						new Handler(Looper.getMainLooper()).post(new Runnable() {
							@Override
							public void run() {
								try {
									eventSink.success(map);
								}catch (IllegalStateException e) {

								}
							}
						});
					}
				});
			}
		});

	}


	private void setTimeOut(MethodCall call, Result result) {
		if (call.hasArgument("timeout")) {
			int timeout = call.argument("timeout");
			FlyVerify.setTimeOut(timeout);
		}
	}

	private void setDebugMode(MethodCall call, Result result) {
		if (call.hasArgument("enable")) {
			boolean debugMode = call.argument("enable");
			FlyVerify.setDebugMode(debugMode);
		}


	}

	private void preVerify(MethodCall call, final Result result) {
		FlyVerify.preVerify(new OperationCallback<Void>() {
			@Override
			public void onComplete(Void o) {
				Map<String, Object> map = new HashMap<String, Object>();
				map.put("success", true);
				onSuccess(result, map);
			}

			@Override
			public void onFailure(VerifyException e) {
				onFail(result, e);
			}
		});
	}


	private void verify(MethodCall call, final Result result) {
		FlyVerify.verify(new VerifyCallback() {
			@Override
			public void onOtherLogin() {
				final Map<String, Object> map = new HashMap<String, Object>();
				map.put("ret", "onOtherLogin");
				new Handler(Looper.getMainLooper()).post(new Runnable() {
					@Override
					public void run() {
						try {
							eventSink.success(map);
						}catch (IllegalStateException e) {

						}
					}
				});

				//onListen("otherCallback",eventSink);
			}

			@Override
			public void onUserCanceled() {
				final Map<String, Object> map = new HashMap<String, Object>();
				map.put("ret", "onUserCanceled");
				new Handler(Looper.getMainLooper()).post(new Runnable() {
					@Override
					public void run() {
						try {
							eventSink.success(map);
						}catch (IllegalStateException e) {

						}
					}
				});
			}

			@Override
			public void onComplete(VerifyResult verifyResult) {
				final Map<String, Object> map = new HashMap<String, Object>();
				//将置换手机号需要的信息全部返回
				map.put("opToken", verifyResult.getOpToken());
				map.put("token", verifyResult.getToken());
				map.put("operator", verifyResult.getOperator());
				//onSuccess(result, map);
				new Handler(Looper.getMainLooper()).post(new Runnable() {
					@Override
					public void run() {
						final Map<String, Object> map2 = new HashMap<>();
						map2.put("ret", map);
						try {
							eventSink.success(map2);
						}catch (IllegalStateException e) {

						}
					}
				});
			}

			@Override
			public void onFailure(VerifyException e) {
				final Map<String, Object> map = new HashMap<>();
				final Map<String, Object> err = new HashMap<>();
				if (e != null) {
					err.put("message", e.getMessage());
					err.put("code", e.getCode());
				}
				//使用 “err” 包装一层
				map.put("err", err);
				new Handler(Looper.getMainLooper()).post(new Runnable() {
					@Override
					public void run() {
						try {
							eventSink.success(map);
						}catch (IllegalStateException e) {

						}

					}
				});
			}
		});
	}

	private void getVersion(Result result) {
		String version = FlyVerify.getVersion();
		try {
			result.success(version);
		}catch (IllegalStateException e) {

		}
	}

	private void onSuccess(final Result result, Map<String, Object> ret) {
		final Map<String, Object> map = new HashMap<>();
		map.put("ret", ret);
		new Handler(Looper.getMainLooper()).post(new Runnable() {
			@Override
			public void run() {
				//将封装好的数据通过result传会给flutter
				try {
					result.success(map);
				}catch (IllegalStateException e) {

				}
			}
		});
	}

	private void onFailForMobileAuth(final Result result, final VerifyException e) {
		new Handler(Looper.getMainLooper()).post(new Runnable() {
			@Override
			public void run() {
				//将错误信息封装成Map
				final Map<String, Object> map = new HashMap<>();
				final Map<String, Object> err = new HashMap<>();
				String message = "";
				String cause = "";
				if (e != null) {
					message = e.getMessage();
					err.put("message", message);
					Throwable throwable = e.getCause();
					if (throwable != null) {
						cause = throwable.toString();
						err.put("cause", cause);
					}
				}
				//使用 “err” 包装一层
				map.put("err", err);
				try {
					eventSink.success(map);
				}catch (IllegalStateException e) {

				}
			}
		});
	}

	private void onFail(final Result result, final VerifyException e) {
		new Handler(Looper.getMainLooper()).post(new Runnable() {
			@Override
			public void run() {
				//将错误信息封装成Map
				final Map<String, Object> map = new HashMap<>();
				final Map<String, Object> err = new HashMap<>();
				if (e != null) {
					err.put("message", e.getMessage());
					err.put("code", e.getCode());
				}
				//使用 “err” 包装一层
				map.put("err", err);
				try {
					result.success(map);
				}catch (IllegalStateException e) {

				}
			}
		});
	}

	private void toast(MethodCall call, final Result result){
		if (call.hasArgument("content")) {
			final String content = call.argument("content");
			new Handler(Looper.getMainLooper()).post(new Runnable() {
				@Override
				public void run() {
					try {
						Toast.makeText(FlyVerify.getContext(), content, Toast.LENGTH_SHORT).show();
					}catch (IllegalStateException e) {

					}
				}
			});
		}
	}

	@Override
	public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
		onAttachedToEngine(binding.getApplicationContext(),binding.getBinaryMessenger());
	}

	@Override
	public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
		methodChannel.setMethodCallHandler(null);
		methodChannel = null;
	}

	private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger){
		methodChannel = new MethodChannel(messenger, METHOD_CHANNEL);
		methodChannel.setMethodCallHandler(this);
		eventChannel = new EventChannel(messenger,EVENT_CHANNEL);
		eventChannel.setStreamHandler(this);
	}


	@Override
	public void onListen(Object arguments, EventChannel.EventSink events) {
		eventSink = events;
		System.out.println("onListen");
	}


	@Override
	public void onCancel(Object arguments) {
	}
}
