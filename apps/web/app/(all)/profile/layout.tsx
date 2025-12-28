// components
import { Outlet } from "react-router";
// wrappers
import { ProjectsAppPowerKProvider } from "@/components/power-k/projects-app-provider";
import { AuthenticationWrapper } from "@/lib/wrappers/authentication-wrapper";
// layout
import { ProfileLayoutSidebar } from "./sidebar";

export default function ProfileSettingsLayout() {
  return (
    <>
      <ProjectsAppPowerKProvider />
<div className="text-lg">Hello WORLD CHUOLINK</div>
      <AuthenticationWrapper>
      <div className="text-lg">Hello WORLD CHUOLINK</div>
        <div className="relative flex h-full w-full overflow-hidden rounded-lg border border-subtle">
        <div className="text-lg">Hello WORLD CHUOLINK</div>
          <ProfileLayoutSidebar />
          <main className="relative flex h-full w-full flex-col overflow-hidden bg-surface-1">
            <div className="h-full w-full overflow-hidden">
              <Outlet />
            </div>
          </main>
        </div>
      </AuthenticationWrapper>
    </>
  );
}
